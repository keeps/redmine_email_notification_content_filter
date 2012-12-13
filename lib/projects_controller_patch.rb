require 'redmine'
# encoding: utf-8
module ProjectsControllerPatch
    def self.included(base) # :nodoc:
       base.send(:include, InstanceMethods)

       base.class_eval do
          alias_method_chain :create, :pluginenabled
       end
    end

    module InstanceMethods
	
    end

    def create_with_pluginenabled
        create_without_pluginenabled
        p = Project.find_by_id(@project.id)
        enabled_module_names = p.enabled_module_names
        enabled_module_names.push('email_notification_content_filter')
        p.enabled_module_names = enabled_module_names
        p.save()
      # can do other stuff for module mod heres
    end
  end
