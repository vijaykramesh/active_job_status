module ActiveJobStatus
  module Hooks
    def self.included(base)
      base.class_eval do
        before_enqueue { job_tracker.enqueued }

        before_perform { job_tracker.performing }

        after_perform { job_tracker.completed }
      end
    end

    private

    def job_tracker
      batch_id = ActiveJobStatus.store.fetch(ActiveJobStatus::JobTracker.batch_for_key(job_id))
      @job_tracker ||= ActiveJobStatus::JobTracker.new(job_id: job_id, batch_id: batch_id)
    end
  end
end
