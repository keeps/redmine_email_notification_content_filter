module MailerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :issue_add, :email_filter
      alias_method_chain :issue_edit, :email_filter
    end
  end

  module InstanceMethods
    def issue_add_with_email_filter(issue, to_users, cc_users)
      if issue.project.module_enabled?('email_notification_content_filter')
        if Setting.plugin_redmine_email_notification_content_filter['removeDescription']
          issue.description = ''
        end
        if Setting.plugin_redmine_email_notification_content_filter['removeSubject']
          issue.subject = ''
        end
      end
      issue_add_without_email_filter(issue, to_users, cc_users)
    end

    def issue_edit_with_email_filter(journal, _to_users, _cc_users)
      if Rails::VERSION::MAJOR >= 3
        issue = journal.journalized
        if issue.project.module_enabled?('email_notification_content_filter')
          if Setting.plugin_redmine_email_notification_content_filter['removeDescription']
            issue.description = ''
          end
          if Setting.plugin_redmine_email_notification_content_filter['removeSubject']
            issue.subject = ''
          end
        end
        redmine_headers 'Project' => issue.project.identifier,
                        'Issue-Id' => issue.id,
                        'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id journal
        references issue
        if Setting.plugin_redmine_email_notification_content_filter['removeNote']
          journal.notes = ''
        end
        @author = journal.user
        s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
        s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
        s << issue.subject
        @issue = issue
        @users = _to_users + _cc_users
        @journal = journal
        @journal_details = journal.visible_details(@users.first)
        @issue_url = url_for(controller: 'issues', action: 'show', id: issue, anchor: "change-#{journal.id}")
        mail to: _to_users,
             cc: _cc_users,
             subject: s
      else
        issue = journal.journalized.reload
        if issue.project.module_enabled?('email_notification_content_filter')
          if Setting.plugin_redmine_email_notification_content_filter['removeDescription']
            issue.description = ''
          end
          if Setting.plugin_redmine_email_notification_content_filter['removeSubject']
            issue.subject = ''
          end
        end
        redmine_headers 'Project' => issue.project.identifier,
                        'Issue-Id' => issue.id,
                        'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id journal
        references issue
        if Setting.plugin_redmine_email_notification_content_filter['removeNote']
          journal.notes = ''
        end
        @author = journal.user
        recipients issue.recipients
        # Watchers in cc
        cc(issue.watcher_recipients - @recipients)
        s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
        s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
        s << issue.subject
        subject s
        body issue: issue,
             journal: journal,
             issue_url: url_for(controller: 'issues', action: 'show', id: issue, anchor: "change-#{journal.id}")

        render_multipart('issue_edit', body)
      end
    end
  end
end
