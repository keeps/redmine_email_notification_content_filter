module ProjectPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      has_many :email_notification_content_filter_configs, :dependent => :destroy
    end
  end

  module InstanceMethods
  end
end
