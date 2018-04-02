module QA
  module Page
    module MergeRequest
      class Show < Page::Base
        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_ready_to_merge.js' do
          element :merge_button
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_merged.vue' do
          element :merged_status, 'The changes were merged into'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_rebase.vue' do
          element :mr_rebase_button
          element :fast_forward_nessage, "Fast-forward merge is not possible"
        end

        def rebase!
          wait(reload: false) do
            click_element :mr_rebase_button

            has_text?("The source branch HEAD has recently changed.")
          end
        end

        def fast_forward_possible?
          !has_text?("Fast-forward merge is not possible")
        end

        def has_merge_button?
          refresh

          has_selector?('.accept-merge-request')
        end

        def merge!
          wait(reload: false) do
            click_element :merge_button

            has_text?("The changes were merged into")
          end
        end
      end
    end
  end
end
