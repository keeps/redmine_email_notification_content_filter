#!/bin/env ruby
# encoding: utf-8

require 'redmine'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3
require 'mailer_patch'

Redmine::Plugin.register :redmine_email_notification_content_filter do
  name 'Redmine Email Notification Content Filter plugin'
  author 'Sébastien Leroux'
  description 'This is a plugin for Redmine that allows to remove the description in the notification emails'
  version '0.0.3'
  author_url 'mailto:sleroux@keep.pt'
  url 'https://github.com/keeps/redmine_email_notification_content_filter'
  settings(:default => {
    'removeDescriptionFromDocument' => 'false',
    'removeDescriptionFromNews' => 'false',
    'removeDescriptionFromIssue' => 'false',
    'removeDescriptionFromCustomField' => 'false'
  }, :partial => 'settings/redmine_email_notification_content_filter')
  project_module :email_notification_content_filter do
    permission :block_email, {:email_notification_content_filter => :show}
  end
end


if Rails::VERSION::MAJOR >= 3
ActionDispatch::Callbacks.to_prepare do
	 require_dependency 'mailer'
  Mailer.send(:include, MailerPatch)
end


else
	Dispatcher.to_prepare do
	 require_dependency 'mailer'
  Mailer.send(:include, MailerPatch)
end

end
