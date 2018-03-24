module ActiveJobStatus
  class JobTracker
    DEFAULT_EXPIRATION = 72.hours.freeze

    def initialize(job_id:, batch_id: nil, store: ActiveJobStatus.store, expiration: ActiveJobStatus.expiration)
      @job_id = job_id
      @batch_id = batch_id
      @store = store
      @expiration = expiration
    end

    def enqueued
      store.write(
        job_id,
        JobStatus::ENQUEUED.to_s,
        expires_in: expiration || DEFAULT_EXPIRATION
      )
    end

    def performing
      store.write(
        job_id,
        JobStatus::WORKING.to_s,
        expires_in: expiration || DEFAULT_EXPIRATION

      )
    end

    def completed
      previous_status = store.fetch(job_id)
      store.write(
        job_id,
        JobStatus::COMPLETED.to_s,
        expires_in: expiration || DEFAULT_EXPIRATION

      )
      remove_from_batch if batch_id && previous_status && previous_status != JobStatus::COMPLETED.to_s
    end

    def deleted
      previous_status = store.fetch(job_id)
      store.delete(job_id)
      remove_from_batch if batch_id && previous_status && previous_status != JobStatus::COMPLETED.to_s
    end

    def remove_from_batch
      remaining_jobs_key = ["remaining_jobs", batch_id].join(":")
      store.decrement(remaining_jobs_key)

      batch_for_key = ["batch_for", job_id].join(":")
      store.delete(batch_for_key)
    end

    attr_reader :job_id, :batch_id, :store, :expiration
  end
end
