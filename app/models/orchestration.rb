require "proxy_api"
require 'orchestration/queue'

module Orchestration
  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      attr_reader :queue, :old
      # stores actions to be performed on our proxies based on priority
      before_validation :set_queue
      before_validation :setup_clone

      # extend our Host model to know how to handle subsystems
      include Orchestration::DHCP
      include Orchestration::DNS
      include Orchestration::TFTP
      include Orchestration::Puppetca
      include Orchestration::Libvirt

      # save handles both creation and update of hosts
      before_save :on_save
      after_destroy :on_destroy
    end
  end

  module InstanceMethods

    protected

    def on_save
      process queue
    end

    def on_destroy
      errors.empty? ? process(queue) : false
    end

    def rollback
      raise ActiveRecord::Rollback
    end

    # log and add to errors
    def failure msg, backtrace=nil
      logger.warn(backtrace ? msg + backtrace.join("\n") : msg)
      errors.add_to_base msg
      false
    end

    public

    # we override this method in order to include checking the
    # after validation callbacks status, as rails by default does
    # not care about their return status.
    def valid?
      super
      errors.empty?
    end

    # we override the destroy method, in order to ensure our queue exists before other callbacks
    # and to process the queue only if we found no errors
    def destroy
      set_queue
      super
    end

    private
    def proxy_error e
      (e.respond_to?(:response) and !e.response.nil?) ? e.response : e
    end
    # Handles the actual queue
    # takes care for running the tasks in order
    # if any of them fail, it rollbacks all completed tasks
    # in order not to keep any left overs in our proxies.
    def process q
      return true if Rails.env == "test"
      # queue is empty - nothing to do.
      return if q.empty?

      # process all pending tasks
      q.pending.each do |task|
        # if we have failures, we don't want to process any more tasks
        next unless q.failed.empty?
        task.status = "running"
        begin
          task.status = execute({:action => task.action}) ? "completed" : "failed"

        rescue => e
          task.status = "failed"
          failed "failed #{e}"
        end
      end

      # if we have no failures - we are done
      return true if q.failed.empty? and q.pending.empty? and errors.empty?

      logger.debug "Rolling back due to a problem: #{q.failed}"
      # handle errors
      # we try to undo all completed operations and trigger a DB rollback
      (q.completed + q.running).sort.reverse_each do |task|
        begin
          task.status = "rollbacked"
          execute({:action => task.action, :rollback => true})
        rescue => e
          # if the operation failed, we can just report upon it
          failed "Failed to perform rollback on #{task.name} - #{e}"
        end
      end

      rollback
    end

    def execute opts = {}
      obj, met = opts[:action]
      rollback = opts[:rollback] || false
      # at the moment, rollback are expected to replace set with del in the method name
      if rollback
        met = met.to_s
        case met
        when /set/
          met.gsub!("set","del")
        when /del/
          met.gsub!("del","set")
        else
          raise "Dont know how to rollback #{met}"
        end
        met = met.to_sym
      end
      if obj.respond_to?(met)
        return obj.send(met)
      else
        failed "invalid method #{met}"
        raise "invalid method #{met}"
      end
    end

    def set_queue
      @queue = Orchestration::Queue.new
    end

    # we keep the before update host object in order to compare changes
    def setup_clone
      return if new_record?
      @old = clone
      for key in (changed_attributes.keys - ["updated_at"])
        @old.send "#{key}=", changed_attributes[key]
      end
    end

  end
end
