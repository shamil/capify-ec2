require 'rubygems'
require 'fog'

# Get rails_env from Capfile
Capistrano::Configuration.instance(:must_exist).load do
  $ec2_rails_env = fetch(:rails_env, nil)
end

class CapifyEc2

  # get config
  def self.ec2_config
    YAML.load(File.new("config/ec2.yml"))
  end

  # get regions
  def self.determine_regions(region = nil)
    region.nil? ? (ec2_config[:aws_params][:regions] || [ec2_config[:aws_params][:region]]) : [region]
  end

  # get running instances
  def self.running_instances(region = nil)
    regions = determine_regions(region)
    instances = []

    regions.each do |region|
      # Connect to AWS according to region
      unless @ec2.instance_of?(Fog::Compute::AWS::Real)
        @ec2 = Fog::Compute.new(
          :provider => 'AWS',
          :aws_access_key_id => ec2_config[:aws_access_key_id],
          :aws_secret_access_key => ec2_config[:aws_secret_access_key],
          :region => region
        )
      end

      project_tag = ec2_config[:project_tag]
      running_instances = @ec2.servers.select do |instance|
        instance.state == "running" && instance.tags["rails_env"] == $ec2_rails_env &&
          (project_tag.nil? || instance.tags["Project"] == project_tag)
      end

      running_instances.each do |instance|
        instance.instance_eval do
          # get tag
          def case_insensitive_tag(key)
            tags[key] || tags[key.downcase]
          end

          # get name
          def name
            name = case_insensitive_tag("Name") || ''
            name.gsub('.', '_')
          end

          # get roles
          # Notice, AWS auto-scaling creates tag with key "aws:autoscaling:groupName"
          def roles
            # collect roles by predifined tags
            role = case_insensitive_tag("Role")
            role_as = case_insensitive_tag("aws:autoscaling:groupName") # get role from autoscaling tag
            roles_tag = case_insensitive_tag("Roles") || '' # get roles from 'Roles' tag, comma delimited

            # join the roles
            roles  = [role] || []
            roles += [role_as] unless role_as.nil?
            roles += roles_tag.split(/\s*,\s*/)
            roles.compact.uniq # remove nil and non-unique elements
          end
        end

        # add to instances array
        instances << instance
      end
    end

    # return the instances
    instances
  end

  def self.get_instances_by_role(role)
    filter_instances_by_role(running_instances, role)
  end

  def self.get_instances_by_region(role, region)
    return unless region
    region_instances = running_instances(region)
    filter_instances_by_role(region_instances,role)
  end

  def self.filter_instances_by_role(instances, role)
    selected_instances = instances.select do |instance|
      server_roles = instance.roles
      server_roles.member?(role.to_s)
    end
  end

  def self.get_instance_by_name(name)
    selected_instances = running_instances.select do |instance|
      value = instance.case_insensitive_tag("Name")
      value == name.to_s
    end.first
  end
end # of CapifyEc2 class
