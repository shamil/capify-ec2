require File.join(File.dirname(__FILE__), '../capify-ec2')
require 'colored'

Capistrano::Configuration.instance(:must_exist).load do
  namespace :ec2 do
    desc "Prints out all ec2 instances. index, name, instance_id, size, dns_name, region, tags"
    task :status do
      roles = fetch(:ec2roles, nil)
      roles = roles.split(/\s*,\s*/) if roles
      instances = []

      # show only specific roles if asked
      if (roles)
        roles.uniq.each { |role| instances += CapifyEc2.get_instances_by_role(role) }
      else
        instances = CapifyEc2.running_instances
      end

      instances.each_with_index do |instance, i|
        puts sprintf "%-11s:   %-40s %-20s %-20s %-62s %-20s (%s)",
          i.to_s.magenta, instance.case_insensitive_tag("Name"), instance.id.red, instance.flavor_id.cyan,
          instance.dns_name.blue, instance.availability_zone.green, instance.roles.join(", ").yellow
      end
    end

    desc "Allows ssh to instance by choosing from list of running instances"
    task :ssh do
      roles = fetch(:ec2roles, nil)
      roles = roles.split(/\s*,\s*/) if roles
      instances = []

      # show only specific roles if asked
      if (roles)
        roles.uniq.each { |role| instances += CapifyEc2.get_instances_by_role(role) }
      else
        instances = CapifyEc2.running_instances
      end

      # show asked servers and let user choose
      status
      server = Capistrano::CLI.ui.ask("Enter # [0]: ").to_i

      instance = instances[server.to_i]
      port = ssh_options[:port] || 22
      login = fetch(:user)
      command = "ssh -p #{port} -l #{login} #{instance.dns_name}"
      puts "Running `#{command}`"
      exec(command)
    end
  end

  def ec2_roles(*roles)
    roles.each {|role| ec2_role(role)}
  end

  def ec2_role(role_name_or_hash)
    role = role_name_or_hash.is_a?(Hash) ? role_name_or_hash : {:name => role_name_or_hash, :options => {}}

    instances = CapifyEc2.get_instances_by_role(role[:name])
    if role[:options].delete(:default)
      instances.each do |instance|
        define_role(role, instance)
      end
    end

    regions = CapifyEc2.ec2_config[:aws_params][:regions] || [CapifyEc2.ec2_config[:aws_params][:region]]
    regions.each do |region|
      define_regions(region, role)
    end unless regions.nil?

    define_role_roles(role, instances)
    define_instance_roles(role, instances)
  end

  def define_regions(region, role)
    instances = CapifyEc2.get_instances_by_region(role[:name], region)
    task region.to_sym do
      remove_default_roles
      instances.each do |instance|
        define_role(role, instance)
      end
    end
  end

  def define_instance_roles(role, instances)
    instances.each do |instance|
      task instance.name.to_sym do
        remove_default_roles
        define_role(role, instance)
      end
    end
  end

  def define_role_roles(role, instances)
    task role[:name].to_sym do
      remove_default_roles
      instances.each do |instance|
        define_role(role, instance)
      end
    end
  end

  def define_role(role, instance)
    subroles = role[:options]
    new_options = {}
    subroles.each {|key, value| new_options[key] = true if value.to_s == instance.name}

    if new_options
      role role[:name].to_sym, instance.dns_name, new_options
    else
      role role[:name].to_sym, instance.dns_name
    end
  end

  def numeric?(object)
    true if Float(object) rescue false
  end

  def remove_default_roles
    roles.reject! { true }
  end

end
