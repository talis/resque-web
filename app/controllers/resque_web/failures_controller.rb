module ResqueWeb
  class FailuresController < ResqueWeb::ApplicationController
    include ResqueWeb::FailureQueueNameHelper

    # Display all jobs in the failure queue
    #
    # @param [Hash] params
    # @option params [String] :class filters failures shown by class
    # @option params [String] :queue filters failures shown by failure queue name
    def index
    end

    # remove an individual job from the failure queue
    def destroy
      Resque::Failure.remove(params[:id])
      redirect_to failures_path(redirect_params)
    end

    # destroy all jobs from the failure queue
    def destroy_all
      # This needs to stay as params[:queue] as if nil it will delete
      # all queues and this is the behaviour that we want
      Resque::Failure.clear(params[:queue])
      redirect_to failures_path(redirect_params)
    end

    # retry an individual job from the failure queue
    def retry
      requeue_single_job(params[:id], failure_queue)
      redirect_to failures_path(redirect_params)
    end

    # retry all jobs from the failure queue
    def retry_all
      if params[:queue].present? || !multiple_failure_queues?
        requeue_queue(failure_queue)
      else
        Resque::Failure.queues.each { |queue| requeue_queue(queue) }
      end
      redirect_to failures_path(redirect_params)
    end

    private

    def requeue_queue(queue)
      (Resque::Failure.count(queue)-1).downto(0).each { |id| requeue_single_job(id, queue) }
    end

    #API agnostic for Resque 2 with duck typing on requeue_and_remove
    def requeue_single_job(id, queue)
      if Resque::Failure.respond_to?(:requeue_and_remove)
        # The API for Resque 2 does not support providing a queue name
        # to requeue_and_remove
        Resque::Failure.requeue_and_remove(id)
      else
        Resque::Failure.requeue(id, queue)
        Resque::Failure.remove(id, queue)
      end
    end

    def redirect_params
      {}.tap do |p|
        if params[:queue].present?
          p[:queue] = params[:queue]
        end
      end
    end

  end
end
