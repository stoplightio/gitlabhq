import Vue from 'vue';
import listItem from '~/repo/components/commit_sidebar/list_item.vue';
import mountComponent from '../../../helpers/vue_mount_component_helper';
import { file } from '../../helpers';

describe('Multi-file editor commit sidebar list item', () => {
  let vm;
  let f;

  beforeEach(() => {
    const Component = Vue.extend(listItem);

    f = file();

    vm = mountComponent(Component, {
      file: f,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders file path', () => {
    expect(vm.$el.querySelector('.multi-file-commit-list-path').textContent.trim()).toBe(f.path);
  });

  describe('computed', () => {
    describe('iconName', () => {
      it('returns modified when not a tempFile', () => {
        expect(vm.iconName).toBe('file-modified');
      });

      it('returns addition when not a tempFile', () => {
        f.tempFile = true;

        expect(vm.iconName).toBe('file-addition');
      });
    });

    describe('iconClass', () => {
      it('returns modified when not a tempFile', () => {
        expect(vm.iconClass).toContain('multi-file-modified');
      });

      it('returns addition when not a tempFile', () => {
        f.tempFile = true;

        expect(vm.iconClass).toContain('multi-file-addition');
      });
    });
  });
});
