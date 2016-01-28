module ResqueWeb
  module FailureQueueNameHelper
    def failure_queue
      multiple_failure_queues? ? params[:queue] : 'failed'
    end

    def multiple_failure_queues?
      Resque::Failure.backend == Resque::Failure::RedisMultiQueue
    end
  end
end
