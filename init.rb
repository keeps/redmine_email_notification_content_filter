require 'redmine'
require 'dispatcher'
require 'mailer_patch'

Redmine::Plugin.register :redmine_email_modifier do
  name 'Redmine Email Modifier plugin'
  author 'Sébastien Leroux'
  description 'This is a plugin for Redmine that allows to remove the description in the notification emails'
  version '0.0.1'
  author_url 'mailto:sleroux@keep.pt'
  settings :default => {
    'removeDescriptionFromDocument' => 'false',
    'removeDescriptionFromNews' => 'false',
    'removeDescriptionFromIssue' => 'false'
  }
  project_module :email_modifier do
    permission :email_modifier_permission, {:email_modifier => :show}
  end
end

Dispatcher.to_prepare do
	 require_dependency 'mailer'
  Mailer.send(:include, MailerPatch)
end
