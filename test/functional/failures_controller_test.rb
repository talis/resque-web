require 'test_helper'
require 'resque/failure/redis_multi_queue'

module ResqueWeb
  class FailuresControllerTest < ActionController::TestCase
    include ControllerTestHelpers

    setup do
      @routes = Engine.routes
    end

    describe "GET /failures" do
      it "renders the index page" do
        visit(:index)
        assert_template :index
      end
    end

    describe "DELETE /failures/:id" do
      it "deletes the failure" do
        Resque::Failure.expects(:remove).with('123')
        visit(:destroy, {:id => 123}, :method => :delete)
        assert_redirected_to failures_path
      end
    end

    describe "DELETE /failures/destroy_all" do
      it "deletes all failures" do
        Resque::Failure.expects(:clear).with('failed')
        visit(:destroy_all, nil, :method => :delete)
        assert_redirected_to failures_path
      end
    end

    describe "PUT /failures/:id/retry" do
      it "retries the failure and remove the original message" do
        Resque::Failure.expects(:requeue_and_remove).with('123')
        visit(:retry, {:id => 123}, :method => :put)
        assert_redirected_to failures_path
      end
      it "retries should work also in case of pre 2.0 Resque" do
        Resque::Failure.expects(:requeue).with('123', 'failed')
        Resque::Failure.expects(:remove).with('123', 'failed')
        visit(:retry, {:id => 123}, :method => :put)
        assert_redirected_to failures_path
      end
    end

    describe "PUT /failures/retry_all" do
      it "retries all failures using requeue if no queue specified" do
        Resque::Failure.stubs(:count).returns(2)
        Resque::Failure.stubs(:requeue_and_remove).returns(true)
        Resque::Failure.expects(:requeue_and_remove).with(0)
        Resque::Failure.expects(:requeue_and_remove).with(1)
        visit(:retry_all, nil, :method => :put)
        assert_redirected_to failures_path
      end
      it "retries all failures should also work case of pre 2.0 Resque" do
        Resque::Failure.stubs(:count).returns(2)
        Resque::Failure.stubs(:requeue).returns(true)
        Resque::Failure.expects(:requeue).with(0, 'failed')
        Resque::Failure.expects(:remove).with(0, 'failed')
        Resque::Failure.expects(:requeue).with(1, 'failed')
        Resque::Failure.expects(:remove).with(1, 'failed')
        visit(:retry_all, nil, :method => :put)
        assert_redirected_to failures_path
      end
      
    end

    describe "With Multiple Failed Queues" do
      setup do
        @routes = Engine.routes
        Resque::Failure.backend = Resque::Failure::RedisMultiQueue
      end

      describe "GET /failures" do
        it "renders the index page when not supplied a queue name" do
          visit(:index)
          assert_template :index
        end
        it "renders the index page when supplied a queue name" do
          visit(:index, {:queue => "my_queue"})
          assert_template :index
        end
      end

      describe "PUT /failures/retry_all" do
        it "retries all failures on all queues if no queue specified" do
          Resque::Failure.stubs(:queues).returns(%w(foo bar))
          Resque::Failure.stubs(:count).with('foo').returns(2)
          Resque::Failure.stubs(:count).with('bar').returns(2)
          Resque::Failure.expects(:requeue).with(0, 'foo')
          Resque::Failure.expects(:remove).with(0, 'foo')
          Resque::Failure.expects(:requeue).with(1, 'foo')
          Resque::Failure.expects(:remove).with(1, 'foo')
          Resque::Failure.expects(:requeue).with(0, 'bar')
          Resque::Failure.expects(:remove).with(0, 'bar')
          Resque::Failure.expects(:requeue).with(1, 'bar')
          Resque::Failure.expects(:remove).with(1, 'bar')
          visit(:retry_all, nil, :method => :put)
          assert_redirected_to failures_path
        end
        
        it "retries all failures using the queue name if queue specified" do
          Resque::Failure.stubs(:count).returns(2)
          Resque::Failure.stubs(:requeue).returns(true)
          Resque::Failure.expects(:requeue).with(0, 'my_queue')
          Resque::Failure.expects(:remove).with(0, 'my_queue')
          Resque::Failure.expects(:requeue).with(1, 'my_queue')
          Resque::Failure.expects(:remove).with(1, 'my_queue')
          visit(:retry_all, {:queue=>"my_queue"}, :method => :put)
          assert_redirected_to failures_path(:queue=>'my_queue')
        end
      end
    end
  end
end
