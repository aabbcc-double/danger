# coding: utf-8
require "danger/request_source/request_source"

describe Danger::RequestSources::BitbucketCloud, host: :bitbucket_cloud do
  let(:env) { stub_env }
  let(:bs) { Danger::RequestSources::BitbucketCloud.new(stub_ci, env) }

  describe "#validates_as_api_source" do
    it "validates_as_api_source for non empty `DANGER_BITBUCKETCLOUD_USERNAME` and `DANGER_BITBUCKETCLOUD_PASSWORD`" do
      expect(bs.validates_as_api_source?).to be true
    end
  end

  describe "#pr_json" do
    before do
      stub_pull_request
      bs.fetch_details
    end

    it "has a non empty pr_json after `fetch_details`" do
      expect(bs.pr_json).to be_truthy
    end

    describe "#pr_json[:id]" do
      it "has fetched the same pull request id as ci_sources's `pull_request_id`" do
        expect(bs.pr_json[:id]).to eql(2080)
      end
    end

    describe "#pr_json[:title]" do
      it "has fetched the pull requests title" do
        expect(bs.pr_json[:title]).to eql("This is a danger test")
      end
    end
  end
end
