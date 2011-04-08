class Redhat < Operatingsystem

  PXEDIR   = "images/pxeboot"
  PXEFILES = {:kernel => "vmlinuz", :initrd => "initrd.img"}

  # outputs kickstart installation medium based on the medium type (NFS or URL)
  # it also convert the $arch string to the current host architecture
  def mediumpath host
    uri = medium_uri(host)
    server = uri.select(:host, :port).compact.join(':')
    dir = uri.select(:path, :query).compact.join('?') unless uri.scheme == 'ftp'

    case uri.scheme
      when 'http', 'https', 'ftp'
         "url --url #{uri.to_s}"
      else
        "nfs --server #{server} --dir #{dir}"
    end
  end

  # installs the epel repo
  def epel host
    epel_url = "http://download.fedora.redhat.com/pub/epel/$major/$arch/epel-release-$os.noarch.rpm"

    case host.operatingsystem.major
    when "4"
      epel_url.gsub!("$os","4-10")
    when "5"
      epel_url.gsub!("$os","5-4")
    when "6"
       epel_url.gsub!("$os","6-5").
         gsub!("/pub/epel/","/pub/epel/beta/") # workaround for hardcoded beta in url, should be remove once RH6 is released
    else
      return ""
    end
    return "su -c 'rpm -Uvh #{medium_uri(host, epel_url)}'"
  end

  def yumrepo host
    if host.respond_to? :yumrepo
      "--enablerepo #{repo}"
    end
  end

  # Override the class representation, as this breaks many rails helpers
  def class
    Operatingsystem
  end

  def boot_files_uri(medium, architecture)
    raise "invalid medium for #{to_s}" unless media.include?(medium)
    raise "invalid architecture for #{to_s}" unless architectures.include?(architecture)
    PXEFILES.values.collect do |img|
      URI.parse("#{medium_vars_to_uri(medium.path, architecture.name, self)}/#{PXEDIR}/#{img}").normalize
    end
  end

  def pxe_type
    "kickstart"
  end

  def url_for_boot(file)
    PXEDIR + "/" + PXEFILES[file]
  end

end
