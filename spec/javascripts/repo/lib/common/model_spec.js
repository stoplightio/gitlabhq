/* global monaco */
import monacoLoader from '~/repo/monaco_loader';
import Model from '~/repo/lib/common/model';
import { file } from '../../helpers';

describe('Multi-file editor library model', () => {
  let model;

  beforeEach((done) => {
    monacoLoader(['vs/editor/editor.main'], () => {
      model = new Model(monaco, file('path'));

      done();
    });
  });

  afterEach(() => {
    model.dispose();
  });

  it('creates original model & new model', () => {
    expect(model.originalModel).not.toBeNull();
    expect(model.model).not.toBeNull();
  });

  describe('path', () => {
    it('returns file path', () => {
      expect(model.path).toBe('path');
    });
  });

  describe('getModel', () => {
    it('returns model', () => {
      expect(model.getModel()).toBe(model.model);
    });
  });

  describe('getOriginalModel', () => {
    it('returns original model', () => {
      expect(model.getOriginalModel()).toBe(model.originalModel);
    });
  });

  describe('onChange', () => {
    it('caches event by path', () => {
      model.onChange(() => {});

      expect(model.events.size).toBe(1);
      expect(model.events.keys().next().value).toBe('path');
    });

    it('calls callback on change', (done) => {
      const spy = jasmine.createSpy();
      model.onChange(spy);

      model.getModel().setValue('123');

      setTimeout(() => {
        expect(spy).toHaveBeenCalledWith(model.getModel(), jasmine.anything());
        done();
      });
    });
  });

  describe('dispose', () => {
    it('calls disposable dispose', () => {
      spyOn(model.disposable, 'dispose').and.callThrough();

      model.dispose();

      expect(model.disposable.dispose).toHaveBeenCalled();
    });

    it('clears events', () => {
      model.onChange(() => {});

      expect(model.events.size).toBe(1);

      model.dispose();

      expect(model.events.size).toBe(0);
    });
  });
});
