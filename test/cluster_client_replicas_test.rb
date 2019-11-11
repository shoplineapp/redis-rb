# frozen_string_literal: true

require_relative 'helper'

# ruby -w -Itest test/cluster_client_replicas_test.rb
class TestClusterClientReplicas < Minitest::Test
  include Helper::Cluster

  def test_client_can_command_with_replica
    r = build_another_client(replica: true)

    100.times do |i|
      assert_equal 'OK', r.set("key#{i}", i)
    end

    r.wait(1, TIMEOUT.to_i * 1000)

    100.times do |i|
      assert_equal i.to_s, r.get("key#{i}")
    end
  end

  def test_client_can_read_with_disconnected_replica
    redirected_node = mock
    redirected_node.stubs(:call).returns(false)

    r = build_another_client(replica: true)
    r._client.stubs(:assign_redirection_node).returns(redirected_node)

    r.set('{key}1', 100)
    r.disconnect!

    assert_equal '100', r.get('{key}1')
  end

  def test_client_can_flush_with_replica
    r = build_another_client(replica: true)

    assert_equal 'OK', r.flushall
    assert_equal 'OK', r.flushdb
  end

  def test_some_reference_commands_are_sent_to_slaves_if_needed
    r = build_another_client(replica: true)

    5.times { |i| r.set("key#{i}", i) }

    r.wait(1, TIMEOUT.to_i * 1000)

    assert_equal %w[key0 key1 key2 key3 key4], r.keys
    assert_equal 5, r.dbsize
  end
end
