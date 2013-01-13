module ProjectsHelperPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :project_settings_tabs, :email_filter
    end
  end

  module InstanceMethods
    # Copied from app/helpers/projects_helper.rb
    def project_settings_tabs_with_email_filter
      tabs = project_settings_tabs_without_email_filter
      tabs = tabs.select {|tab| User.current.allowed_to?(tab[:action], @project)}

      action_permission = { :controller => :email_notification_content_filter, :action => :manage }
      if User.current.allowed_to?(action_permission, @project)
        tabs << {
          :name => 'email_filter',
          :action => :manage_email_notification_content_filter,
          :partial => 'projects/settings/manage_email_notification_content_filter',
          :label => :email_notification_content_filter_configuration_tab
        }
      end

      tabs
    end
  end
end
