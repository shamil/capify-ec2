require File.join(File.dirname(__FILE__), '../capify-ec2')
require 'colored'

Capistrano::Configuration.instance(:must_exist).load do
  namespace :ec2 do
    desc "Prints out all ec2 instances. index, name, instance_id, size, dns_name, region, tags"
    task :status do
      CapifyEc2.running_instances.each_with_index do |instance, i|
        puts sprintf "%-11s:   %-40s %-20s %-20s %-62s %-20s (%s)",
          i.to_s.magenta, instance.case_insensitive_tag("Name"), instance.id.red, instance.flavor_id.cyan,
          instance.dns_name.blue, instance.availability_zone.green, instance.roles.join(", ").yellow
      end
    end
  end

  def ec2_roles(*roles)
    roles.each {|role| ec2_role(role)}
  end

  def ec2_role(role_name_or_hash)
    role = role_name_or_hash.is_a?(Hash) ? role_name_or_hash : {:name => role_name_or_hash,:options => {}}

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
