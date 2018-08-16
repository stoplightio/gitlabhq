import flash from '~/flash';
import { __ } from '~/locale';
import service from '../../services';
import * as types from '../mutation_types';

export const getProjectData = ({ commit, state }, { namespace, projectId, force = false } = {}) =>
  new Promise((resolve, reject) => {
    if (!state.projects[`${namespace}/${projectId}`] || force) {
      commit(types.TOGGLE_LOADING, { entry: state });
      service
        .getProjectData(namespace, projectId)
        .then(res => res.data)
        .then(data => {
          commit(types.TOGGLE_LOADING, { entry: state });
          commit(types.SET_PROJECT, { projectPath: `${namespace}/${projectId}`, project: data });
          commit(types.SET_CURRENT_PROJECT, `${namespace}/${projectId}`);
          resolve(data);
        })
        .catch(() => {
          flash(
            __('Error loading project data. Please try again.'),
            'alert',
            document,
            null,
            false,
            true,
          );
          reject(new Error(`Project not loaded ${namespace}/${projectId}`));
        });
    } else {
      resolve(state.projects[`${namespace}/${projectId}`]);
    }
  });

export const getBranchData = ({ commit, state }, { projectId, branchId, force = false } = {}) =>
  new Promise((resolve, reject) => {
    if (
      typeof state.projects[`${projectId}`] === 'undefined' ||
      !state.projects[`${projectId}`].branches[branchId] ||
      force
    ) {
      service
        .getBranchData(`${projectId}`, branchId)
        .then(({ data }) => {
          const { id } = data.commit;
          commit(types.SET_BRANCH, {
            projectPath: `${projectId}`,
            branchName: branchId,
            branch: data,
          });
          commit(types.SET_BRANCH_WORKING_REFERENCE, { projectId, branchId, reference: id });
          resolve(data);
        })
        .catch(() => {
          flash(
            __('Error loading branch data. Please try again.'),
            'alert',
            document,
            null,
            false,
            true,
          );
          reject(new Error(`Branch not loaded - ${projectId}/${branchId}`));
        });
    } else {
      resolve(state.projects[`${projectId}`].branches[branchId]);
    }
  });

export const refreshLastCommitData = ({ commit }, { projectId, branchId } = {}) =>
  service
    .getBranchData(projectId, branchId)
    .then(({ data }) => {
      commit(types.SET_BRANCH_COMMIT, {
        projectId,
        branchId,
        commit: data.commit,
      });
    })
    .catch(() => {
      flash(__('Error loading last commit.'), 'alert', document, null, false, true);
    });
