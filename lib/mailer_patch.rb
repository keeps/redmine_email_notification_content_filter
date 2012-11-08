module MailerPatch
    def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :issue_add, :description_removed
      alias_method_chain :issue_edit, :description_removed
    end
  end

  module InstanceMethods
    def issue_add_with_description_removed(issue)
	if issue.project.module_enabled?('email_notification_content_filter')
		issue.description=""
	end
	issue_add_without_description_removed(issue)
    end
    def document_added_with_description_removed(document)
	if document.project.module_enabled?('email_notification_content_filter')
		document.description=""
	end
	document_added_without_description_removed(document)
    end
    def issue_edit_with_description_removed(journal)
	issue = journal.journalized.reload
	if issue.project.module_enabled?('email_notification_content_filter')
		issue.description=""
	end
    redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id journal
    references issue
    @author = journal.user
    recipients issue.recipients
    # Watchers in cc
    cc(issue.watcher_recipients - @recipients)
    s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
    s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
    s << issue.subject
    subject s
    body :issue => issue,
         :journal => journal,
         :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")

    render_multipart('issue_edit', body)
    end

  end
  end
