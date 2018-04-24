import Vue from 'vue';
import { visitUrl } from '~/lib/utils/url_utility';
import flash from '~/flash';
import * as types from './mutation_types';
import FilesDecoratorWorker from './workers/files_decorator_worker';

export const redirectToUrl = (_, url) => visitUrl(url);

export const setInitialData = ({ commit }, data) => commit(types.SET_INITIAL_DATA, data);

export const discardAllChanges = ({ state, commit, dispatch }) => {
  state.changedFiles.forEach(file => {
    commit(types.DISCARD_FILE_CHANGES, file.path);

    if (file.tempFile) {
      dispatch('closeFile', file.path);
    }
  });

  commit(types.REMOVE_ALL_CHANGES_FILES);
};

export const closeAllFiles = ({ state, dispatch }) => {
  state.openFiles.forEach(file => dispatch('closeFile', file));
};

export const setPanelCollapsedStatus = ({ commit }, { side, collapsed }) => {
  if (side === 'left') {
    commit(types.SET_LEFT_PANEL_COLLAPSED, collapsed);
  } else {
    commit(types.SET_RIGHT_PANEL_COLLAPSED, collapsed);
  }
};

export const setResizingStatus = ({ commit }, resizing) => {
  commit(types.SET_RESIZING_STATUS, resizing);
};

export const createTempEntry = (
  { state, commit, dispatch },
  { branchId, name, type, content = '', base64 = false },
) =>
  new Promise(resolve => {
    const worker = new FilesDecoratorWorker();
    const fullName = name.slice(-1) !== '/' && type === 'tree' ? `${name}/` : name;

    if (state.entries[name]) {
      flash(
        `The name "${name.split('/').pop()}" is already taken in this directory.`,
        'alert',
        document,
        null,
        false,
        true,
      );

      resolve();

      return null;
    }

    worker.addEventListener('message', ({ data }) => {
      const { file } = data;

      worker.terminate();

      commit(types.CREATE_TMP_ENTRY, {
        data,
        projectId: state.currentProjectId,
        branchId,
      });

      if (type === 'blob') {
        commit(types.TOGGLE_FILE_OPEN, file.path);
        commit(types.ADD_FILE_TO_CHANGED, file.path);
        dispatch('setFileActive', file.path);
      }

      resolve(file);
    });

    worker.postMessage({
      data: [fullName],
      projectId: state.currentProjectId,
      branchId,
      type,
      tempFile: true,
      base64,
      content,
    });

    return null;
  });

export const scrollToTab = () => {
  Vue.nextTick(() => {
    const tabs = document.getElementById('tabs');

    if (tabs) {
      const tabEl = tabs.querySelector('.active .repo-tab');

      tabEl.focus();
    }
  });
};

export const updateViewer = ({ commit }, viewer) => {
  commit(types.UPDATE_VIEWER, viewer);
};

export const updateDelayViewerUpdated = ({ commit }, delay) => {
  commit(types.UPDATE_DELAY_VIEWER_CHANGE, delay);
};

export * from './actions/tree';
export * from './actions/file';
export * from './actions/project';
export * from './actions/merge_request';
