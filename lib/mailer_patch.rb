module MailerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :issue_add, :email_filter
      alias_method_chain :issue_edit, :email_filter
    end
  end

  module InstanceMethods
    # Copied from app/models/mailer.rb
    def issue_add_with_email_filter(issue)
      if issue.project.module_enabled?('email_notification_content_filter')
        if Setting.plugin_redmine_email_notification_content_filter['removeDescription']
          issue.description = ""
        end
        if Setting.plugin_redmine_email_notification_content_filter['removeSubject']
          issue.subject = ""
        end
      end
      issue_add_without_email_filter(issue)
    end

    def issue_edit_with_email_filter(journal)
      issue = journal.journalized.reload
      if issue.project.module_enabled?('email_notification_content_filter')
        if Setting.plugin_redmine_email_notification_content_filter['removeDescription']
          issue.description = ""
        end
        if Setting.plugin_redmine_email_notification_content_filter['removeSubject']
          issue.subject = ""
        end
      end
      redmine_headers 'Project' => issue.project.identifier,
        'Issue-Id' => issue.id,
        'Issue-Author' => issue.author.login
      redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
      message_id journal
      references issue
      if Setting.plugin_redmine_email_notification_content_filter['removeNote']
        journal.notes = ""
      end
      @author = journal.user
      to_recipients = issue.recipients
      # Watchers in cc
      cc_recipients = issue.watcher_recipients - to_recipients
      s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
      s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
      s << issue.subject

      @issue = issue
      @journal = journal
      @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")

      mail(:to => to_recipients, :subject => s, :template_name => 'issue_edit') do |format|
        format.html
        format.text
      end
    end
  end
end
