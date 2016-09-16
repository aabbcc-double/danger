# coding: utf-8
require "danger/helpers/comments_helper"

module Danger
  module RequestSources
    class BitbucketCloud < RequestSource
      include Danger::Helpers::CommentsHelper
      attr_accessor :pr_json

      def initialize(ci_source, environment)
        self.ci_source = ci_source
        self.environment = environment

        project, slug = ci_source.repo_slug.split("/")
        @api = BitbucketCloudAPI.new(project, slug, ci_source.pull_request_id, environment)
      end

      def validates_as_ci?
        # TODO: ???
        true
      end

      def validates_as_api_source?
        @api.credentials_given?
      end

      def scm
        @scm ||= GitRepo.new
      end

      def host
        @host ||= @api.host
      end

      def fetch_details
        self.pr_json = @api.fetch_pr_json
      end

      def setup_danger_branches
        base_commit = self.pr_json[:destination][:commit][:hash]
        head_commit = self.pr_json[:source][:commit][:hash]

        # Next, we want to ensure that we have a version of the current branch at a known location
        self.scm.exec "branch #{EnvironmentManager.danger_base_branch} #{base_commit}"

        # OK, so we want to ensure that we have a known head branch, this will always represent
        # the head of the PR ( e.g. the most recent commit that will be merged. )
        self.scm.exec "branch #{EnvironmentManager.danger_head_branch} #{head_commit}"
      end

      def organisation
        nil
      end

      def update_pull_request!(warnings: [], errors: [], messages: [], markdowns: [], danger_id: "danger")
        delete_old_comments(danger_id: danger_id)

        comment = generate_description(warnings: warnings, errors: errors)
        comment += "\n\n"
        comment += generate_comment(warnings: warnings,
                                     errors: errors,
                                   messages: messages,
                                  markdowns: markdowns,
                        previous_violations: {},
                                  danger_id: danger_id,
                                   template: "bitbucket_server")

        @api.post_comment(comment)
      end

      def delete_old_comments(danger_id: "danger")
        @api.fetch_last_comments.each do |c|
          @api.delete_comment(c[:id]) if c[:content][:raw] =~ /generated_by_#{danger_id}/
        end
      end
    end
  end
end
