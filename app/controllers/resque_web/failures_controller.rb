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
      Resque::Failure.clear(failure_queue)
      redirect_to failures_path(redirect_params)
    end

    # retry an individual job from the failure queue
    def retry
      reque_single_job(params[:id])
      redirect_to failures_path(redirect_params)
    end

    # retry all jobs from the failure queue
    def retry_all
      (Resque::Failure.count(failure_queue)-1).downto(0).each { |id| reque_single_job(id) }
      redirect_to failures_path(redirect_params)
    end

    private

    #API agnostic for Resque 2 with duck typing on requeue_and_remove
    def reque_single_job(id)
      if Resque::Failure.respond_to?(:requeue_and_remove)
        Resque::Failure.requeue_and_remove(id)
      else
        Resque::Failure.requeue(id, failure_queue)
        Resque::Failure.remove(id, failure_queue)
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
