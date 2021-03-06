<script>
import { mapActions, mapState } from 'vuex';
import { GlEmptyState, GlButton, GlLink, GlLoadingIcon, GlTable } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { __ } from '~/locale';
import TrackEventDirective from '~/vue_shared/directives/track_event';
import { trackViewInSentryOptions, trackClickErrorLinkToSentryOptions } from '../utils';

export default {
  fields: [
    { key: 'error', label: __('Open errors'), thClass: 'w-70p' },
    { key: 'events', label: __('Events') },
    { key: 'users', label: __('Users') },
    { key: 'lastSeen', label: __('Last seen'), thClass: 'w-15p' },
  ],
  components: {
    GlEmptyState,
    GlButton,
    GlLink,
    GlLoadingIcon,
    GlTable,
    Icon,
    TimeAgo,
  },
  directives: {
    TrackEvent: TrackEventDirective,
  },
  props: {
    indexPath: {
      type: String,
      required: true,
    },
    enableErrorTrackingLink: {
      type: String,
      required: true,
    },
    errorTrackingEnabled: {
      type: Boolean,
      required: true,
    },
    illustrationPath: {
      type: String,
      required: true,
    },
    userCanEnableErrorTracking: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState(['errors', 'externalUrl', 'loading']),
  },
  created() {
    if (this.errorTrackingEnabled) {
      this.startPolling(this.indexPath);
    }
  },
  methods: {
    ...mapActions(['startPolling', 'restartPolling']),
    trackViewInSentryOptions,
    trackClickErrorLinkToSentryOptions,
  },
};
</script>

<template>
  <div>
    <div v-if="errorTrackingEnabled">
      <div v-if="loading" class="py-3">
        <gl-loading-icon :size="3" />
      </div>
      <div v-else>
        <div class="d-flex justify-content-end">
          <gl-button
            v-track-event="trackViewInSentryOptions(externalUrl)"
            class="my-3 ml-auto"
            variant="primary"
            :href="externalUrl"
            target="_blank"
          >
            {{ __('View in Sentry') }}
            <icon name="external-link" class="flex-shrink-0" />
          </gl-button>
        </div>

        <gl-table :items="errors" :fields="$options.fields" :show-empty="true" fixed stacked="sm">
          <template slot="HEAD_events" slot-scope="data">
            <div class="text-md-right">{{ data.label }}</div>
          </template>
          <template slot="HEAD_users" slot-scope="data">
            <div class="text-md-right">{{ data.label }}</div>
          </template>
          <template slot="error" slot-scope="errors">
            <div class="d-flex flex-column">
              <gl-link
                v-track-event="trackClickErrorLinkToSentryOptions(errors.item.externalUrl)"
                :href="errors.item.externalUrl"
                class="d-flex text-dark"
                target="_blank"
              >
                <strong class="text-truncate">{{ errors.item.title.trim() }}</strong>
                <icon name="external-link" class="ml-1 flex-shrink-0" />
              </gl-link>
              <span class="text-secondary text-truncate">
                {{ errors.item.culprit }}
              </span>
            </div>
          </template>

          <template slot="events" slot-scope="errors">
            <div class="text-md-right">{{ errors.item.count }}</div>
          </template>

          <template slot="users" slot-scope="errors">
            <div class="text-md-right">{{ errors.item.userCount }}</div>
          </template>

          <template slot="lastSeen" slot-scope="errors">
            <div class="d-flex align-items-center">
              <time-ago :time="errors.item.lastSeen" class="text-secondary" />
            </div>
          </template>
          <template slot="empty">
            <div ref="empty">
              {{ __('No errors to display.') }}
              <gl-link class="js-try-again" @click="restartPolling">
                {{ __('Check again') }}
              </gl-link>
            </div>
          </template>
        </gl-table>
      </div>
    </div>
    <div v-else-if="userCanEnableErrorTracking">
      <gl-empty-state
        :title="__('Get started with error tracking')"
        :description="__('Monitor your errors by integrating with Sentry.')"
        :primary-button-text="__('Enable error tracking')"
        :primary-button-link="enableErrorTrackingLink"
        :svg-path="illustrationPath"
      />
    </div>
    <div v-else>
      <gl-empty-state :title="__('Get started with error tracking')" :svg-path="illustrationPath">
        <template #description>
          <div>
            <span>{{ __('Monitor your errors by integrating with Sentry.') }}</span>
            <a href="/help/user/project/operations/error_tracking.html">
              {{ __('More information') }}
            </a>
          </div>
        </template>
      </gl-empty-state>
    </div>
  </div>
</template>
