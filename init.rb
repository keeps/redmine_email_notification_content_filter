require 'redmine'
require 'mailer_patch'

Redmine::Plugin.register :redmine_email_notification_content_filter do
  name 'Redmine Email Notification Content Filter plugin'
  author 'Sébastien Leroux'
  description 'This is a plugin for Redmine that allows to remove the description in the notification emails'
  version '0.0.1'
  author_url 'mailto:sleroux@keep.pt'
  url 'https://github.com/keeps/redmine_email_notification_content_filter'
  project_module :email_notification_content_filter do
    permission :manage, {:email_notification_content_filter => :manage}
  end
end

ActionDispatch::Callbacks.to_prepare do
	require_dependency 'mailer'
  Mailer.send(:include, MailerPatch)
  Project.send(:include, ProjectPatch)
  ProjectsHelper.send(:include, ProjectsHelperPatch)
end
