import _ from 'underscore';

export const notes = state => state.notes;
export const targetNoteHash = state => state.targetNoteHash;

export const getNotesData = state => state.notesData;
export const getNotesDataByProp = state => prop => state.notesData[prop];

export const getNoteableData = state => state.noteableData;
export const getNoteableDataByProp = state => prop => state.noteableData[prop];
export const openState = state => state.noteableData.state;

export const getUserData = state => state.userData || {};
export const getUserDataByProp = state => prop => state.userData && state.userData[prop];

export const notesById = state => state.notes.reduce((acc, note) => {
  note.notes.every(n => Object.assign(acc, { [n.id]: n }));
  return acc;
}, {});

const reverseNotes = array => array.slice(0).reverse();
const isLastNote = (note, state) => !note.system &&
  state.userData && note.author &&
  note.author.id === state.userData.id;

export const getCurrentUserLastNote = state => _.flatten(
    reverseNotes(state.notes)
    .map(note => reverseNotes(note.notes)),
  ).find(el => isLastNote(el, state));

export const getDiscussionLastNote = state => discussion => reverseNotes(discussion.notes)
  .find(el => isLastNote(el, state));

export const discussionCount = (state) => {
  const discussions = state.notes.filter(n => !n.individual_note);

  return discussions.length;
};

export const unresolvedDiscussions = (state, getters) => {
  const resolvedMap = getters.resolvedDiscussionsById;

  return state.notes.filter(n => !n.individual_note && !resolvedMap[n.id]);
};

export const resolvedDiscussionsById = (state) => {
  const map = {};

  state.notes.forEach((n) => {
    if (n.notes) {
      const resolved = n.notes.every(note => note.resolved && !note.system);

      if (resolved) {
        map[n.id] = n;
      }
    }
  });

  return map;
};

export const resolvedDiscussionCount = (state, getters) => {
  const resolvedMap = getters.resolvedDiscussionsById;

  return Object.keys(resolvedMap).length;
};
