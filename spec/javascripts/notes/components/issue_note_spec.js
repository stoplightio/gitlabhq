
import Vue from 'vue';
import store from '~/notes/stores';
import issueNote from '~/notes/components/issue_note.vue';
import { noteableDataMock, notesDataMock, note } from '../mock_data';

describe('issue_note', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(issueNote);

    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    vm = new Component({
      store,
      propsData: {
        note,
      },
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render user information', () => {
    expect(vm.$el.querySelector('.user-avatar-link img').getAttribute('src')).toEqual(note.author.avatar_url);
  });

  it('should render note header content', () => {
    expect(vm.$el.querySelector('.note-header .note-header-author-name').textContent.trim()).toEqual(note.author.name);
    expect(vm.$el.querySelector('.note-header .note-headline-meta').textContent.trim()).toContain('commented');
  });

  it('should render note actions', () => {
    expect(vm.$el.querySelector('.note-actions')).toBeDefined();
  });

  it('should render issue body', () => {
    expect(vm.$el.querySelector('.note-text').innerHTML).toEqual(note.note_html);
  });

  it('prevents note preview xss', (done) => {
    const imgSrc = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
    const noteBody = `<img src="${imgSrc}" onload="alert(1)" />`;
    const alertSpy = spyOn(window, 'alert');
    vm.updateNote = () => new Promise($.noop);

    vm.formUpdateHandler(noteBody, null, $.noop);

    setTimeout(() => {
      expect(alertSpy).not.toHaveBeenCalled();
      expect(vm.note.note_html).toEqual(_.escape(noteBody));
      done();
    }, 0);
  });
});
