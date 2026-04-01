/**
 * A2UI Component Catalog — Vue 3 Implementation
 *
 * Maps A2UI component type strings to Vue components.
 * Uses Vue's h() render function for maximum flexibility.
 *
 * React equivalent: catalog object mapping type → React component
 * Vue equivalent:   catalog object mapping type → { setup/render } component
 */
import { h, defineComponent, type PropType } from 'vue'
import type { ComponentUpdate, BoundValue } from '../../types'

// ── Helper: resolve BoundValue to display string ─────────────────────────

function resolveText(val: unknown): string {
  if (val == null) return ''
  if (typeof val === 'string') return val
  if (typeof val === 'number' || typeof val === 'boolean') return String(val)
  return JSON.stringify(val)
}

// ── Text ─────────────────────────────────────────────────────────────────

export const A2Text = defineComponent({
  name: 'A2Text',
  props: {
    text: { type: [String, Number, Boolean] as PropType<string | number | boolean>, default: '' },
    variant: { type: String as PropType<'headline' | 'title' | 'body' | 'caption'>, default: 'body' },
    color: { type: String, default: '' },
  },
  setup(props) {
    const tagMap: Record<string, string> = {
      headline: 'h1',
      title:    'h3',
      body:     'p',
      caption:  'span',
    }
    return () =>
      h(tagMap[props.variant] ?? 'p', {
        class: `a2ui-text a2ui-text--${props.variant}`,
        style: props.color ? { color: props.color } : {},
      }, resolveText(props.text))
  },
})

// ── Button ───────────────────────────────────────────────────────────────

export const A2Button = defineComponent({
  name: 'A2Button',
  props: {
    label:    { type: [String, Number, Boolean] as PropType<string | number | boolean>, default: 'Button' },
    primary:  { type: Boolean, default: false },
    variant:  { type: String as PropType<'filled' | 'outlined' | 'text'>, default: 'outlined' },
    disabled: { type: Boolean, default: false },
    actionId: { type: String, default: '' },
  },
  emits: ['action'],
  setup(props, { emit }) {
    return () =>
      h('button', {
        class: [
          'a2ui-btn',
          props.primary || props.variant === 'filled' ? 'a2ui-btn--filled' : '',
          props.variant === 'outlined' ? 'a2ui-btn--outlined' : '',
          props.variant === 'text'     ? 'a2ui-btn--text'     : '',
        ].filter(Boolean),
        disabled: props.disabled,
        onClick: () => emit('action', { actionId: props.actionId }),
      }, resolveText(props.label))
  },
})

// ── TextField ────────────────────────────────────────────────────────────

export const A2TextField = defineComponent({
  name: 'A2TextField',
  props: {
    label:       { type: String, default: '' },
    text:        { type: String, default: '' },   // v0.8 prop name
    value:       { type: String, default: '' },   // v0.9 prop name
    placeholder: { type: String, default: '' },
    dataPath:    { type: String, default: '' },   // for two-way binding
  },
  emits: ['update', 'action'],
  setup(props, { emit }) {
    return () =>
      h('div', { class: 'a2ui-field' }, [
        props.label && h('label', { class: 'a2ui-field__label' }, props.label),
        h('input', {
          class: 'a2ui-field__input',
          type: 'text',
          value: props.text || props.value,
          placeholder: props.placeholder,
          onInput: (e: Event) => {
            const val = (e.target as HTMLInputElement).value
            emit('update', { path: props.dataPath, value: val })
          },
        }),
      ])
  },
})

// ── CheckBox ─────────────────────────────────────────────────────────────

export const A2CheckBox = defineComponent({
  name: 'A2CheckBox',
  props: {
    label:    { type: String, default: '' },
    checked:  { type: Boolean, default: false },
    dataPath: { type: String, default: '' },
  },
  emits: ['update'],
  setup(props, { emit }) {
    return () =>
      h('label', { class: 'a2ui-checkbox' }, [
        h('input', {
          type: 'checkbox',
          checked: props.checked,
          onChange: (e: Event) => {
            const val = (e.target as HTMLInputElement).checked
            emit('update', { path: props.dataPath, value: val })
          },
        }),
        h('span', { class: 'a2ui-checkbox__label' }, props.label),
      ])
  },
})

// ── Slider ───────────────────────────────────────────────────────────────

export const A2Slider = defineComponent({
  name: 'A2Slider',
  props: {
    value:    { type: Number, default: 0 },
    minValue: { type: Number, default: 0 },  // v0.8
    maxValue: { type: Number, default: 100 }, // v0.8
    min:      { type: Number, default: 0 },  // v0.9
    max:      { type: Number, default: 100 }, // v0.9
    step:     { type: Number, default: 1 },
    dataPath: { type: String, default: '' },
  },
  emits: ['update'],
  setup(props, { emit }) {
    return () =>
      h('input', {
        class: 'a2ui-slider',
        type: 'range',
        min: props.min || props.minValue,
        max: props.max || props.maxValue,
        step: props.step,
        value: props.value,
        onInput: (e: Event) => {
          const val = Number((e.target as HTMLInputElement).value)
          emit('update', { path: props.dataPath, value: val })
        },
      })
  },
})

// ── ChoicePicker / Select ────────────────────────────────────────────────

export const A2ChoicePicker = defineComponent({
  name: 'A2ChoicePicker',
  props: {
    label:    { type: String, default: '' },
    options:  { type: Array as PropType<string[]>, default: () => [] },
    value:    { type: String, default: '' },
    dataPath: { type: String, default: '' },
  },
  emits: ['update'],
  setup(props, { emit }) {
    return () =>
      h('div', { class: 'a2ui-choice' }, [
        props.label && h('label', { class: 'a2ui-choice__label' }, props.label),
        h('select', {
          class: 'a2ui-choice__select',
          value: props.value,
          onChange: (e: Event) => {
            const val = (e.target as HTMLSelectElement).value
            emit('update', { path: props.dataPath, value: val })
          },
        },
        props.options.map(opt =>
          h('option', { key: opt, value: opt }, opt)
        )),
      ])
  },
})

// ── DateTimeInput ────────────────────────────────────────────────────────

export const A2DateTimeInput = defineComponent({
  name: 'A2DateTimeInput',
  props: {
    label:    { type: String, default: '' },
    value:    { type: String, default: '' },
    mode:     { type: String as PropType<'date' | 'time' | 'datetime'>, default: 'date' },
    dataPath: { type: String, default: '' },
  },
  emits: ['update'],
  setup(props, { emit }) {
    const typeMap: Record<string, string> = {
      date:     'date',
      time:     'time',
      datetime: 'datetime-local',
    }
    return () =>
      h('div', { class: 'a2ui-datetime' }, [
        props.label && h('label', { class: 'a2ui-datetime__label' }, props.label),
        h('input', {
          class: 'a2ui-datetime__input',
          type: typeMap[props.mode] ?? 'date',
          value: props.value,
          onInput: (e: Event) => {
            emit('update', { path: props.dataPath, value: (e.target as HTMLInputElement).value })
          },
        }),
      ])
  },
})

// ── Image ─────────────────────────────────────────────────────────────────

export const A2Image = defineComponent({
  name: 'A2Image',
  props: {
    src: { type: String, default: '' },
    alt: { type: String, default: '' },
    fit: { type: String as PropType<'cover' | 'contain' | 'fill'>, default: 'cover' },
  },
  setup(props) {
    return () =>
      h('img', {
        class: 'a2ui-image',
        src: props.src,
        alt: props.alt,
        style: { objectFit: props.fit },
      })
  },
})

// ── Icon ──────────────────────────────────────────────────────────────────

export const A2Icon = defineComponent({
  name: 'A2Icon',
  props: {
    name:  { type: String, default: '' },
    size:  { type: [String, Number], default: '24px' },
    color: { type: String, default: 'currentColor' },
  },
  setup(props) {
    return () =>
      h('span', {
        class: `a2ui-icon material-icons`,
        style: {
          fontSize: typeof props.size === 'number' ? `${props.size}px` : props.size,
          color: props.color,
        },
        'aria-hidden': 'true',
      }, props.name)
  },
})

// ── Divider ───────────────────────────────────────────────────────────────

export const A2Divider = defineComponent({
  name: 'A2Divider',
  setup() {
    return () => h('hr', { class: 'a2ui-divider' })
  },
})

// ── Card ──────────────────────────────────────────────────────────────────

export const A2Card = defineComponent({
  name: 'A2Card',
  props: {
    elevation: { type: Number, default: 1 },
    padding:   { type: String, default: '16px' },
  },
  setup(props, { slots }) {
    return () =>
      h('div', {
        class: `a2ui-card a2ui-card--elevation-${props.elevation}`,
        style: { padding: props.padding },
      }, slots.default?.())
  },
})

// ── Row ───────────────────────────────────────────────────────────────────

export const A2Row = defineComponent({
  name: 'A2Row',
  props: {
    gap:     { type: String, default: '8px' },
    align:   { type: String as PropType<'start' | 'center' | 'end' | 'stretch'>, default: 'center' },
    justify: { type: String as PropType<'start' | 'center' | 'end' | 'between' | 'around'>, default: 'start' },
    wrap:    { type: Boolean, default: false },
  },
  setup(props, { slots }) {
    const justifyMap: Record<string, string> = {
      start:   'flex-start',
      center:  'center',
      end:     'flex-end',
      between: 'space-between',
      around:  'space-around',
    }
    const alignMap: Record<string, string> = {
      start:   'flex-start',
      center:  'center',
      end:     'flex-end',
      stretch: 'stretch',
    }
    return () =>
      h('div', {
        class: 'a2ui-row',
        style: {
          display: 'flex',
          flexDirection: 'row',
          gap: props.gap,
          alignItems: alignMap[props.align] ?? 'center',
          justifyContent: justifyMap[props.justify] ?? 'flex-start',
          flexWrap: props.wrap ? 'wrap' : 'nowrap',
        },
      }, slots.default?.())
  },
})

// ── Column ────────────────────────────────────────────────────────────────

export const A2Column = defineComponent({
  name: 'A2Column',
  props: {
    gap:   { type: String, default: '8px' },
    align: { type: String as PropType<'start' | 'center' | 'end' | 'stretch'>, default: 'stretch' },
    flex:  { type: Number, default: 0 },  // flex-grow weight
  },
  setup(props, { slots }) {
    return () =>
      h('div', {
        class: 'a2ui-column',
        style: {
          display: 'flex',
          flexDirection: 'column',
          gap: props.gap,
          alignItems: props.align === 'stretch'
            ? 'stretch'
            : props.align === 'center'
            ? 'center'
            : props.align === 'end'
            ? 'flex-end'
            : 'flex-start',
          flex: props.flex > 0 ? props.flex : undefined,
        },
      }, slots.default?.())
  },
})

// ── List ──────────────────────────────────────────────────────────────────

export const A2List = defineComponent({
  name: 'A2List',
  setup(_, { slots }) {
    return () =>
      h('div', { class: 'a2ui-list' }, slots.default?.())
  },
})

// ── Modal ─────────────────────────────────────────────────────────────────

export const A2Modal = defineComponent({
  name: 'A2Modal',
  props: {
    open:  { type: Boolean, default: false },
    title: { type: String, default: '' },
  },
  emits: ['close'],
  setup(props, { slots, emit }) {
    return () =>
      props.open
        ? h('div', { class: 'a2ui-modal-overlay', onClick: () => emit('close') }, [
            h('div', { class: 'a2ui-modal', onClick: (e: Event) => e.stopPropagation() }, [
              props.title && h('div', { class: 'a2ui-modal__header' }, [
                h('h2', { class: 'a2ui-modal__title' }, props.title),
                h('button', { class: 'a2ui-modal__close', onClick: () => emit('close') }, '×'),
              ]),
              h('div', { class: 'a2ui-modal__body' }, slots.default?.()),
            ]),
          ])
        : null
  },
})

// ── Default Catalog ───────────────────────────────────────────────────────

export const DEFAULT_CATALOG: Record<string, unknown> = {
  Text:          A2Text,
  Button:        A2Button,
  TextField:     A2TextField,
  CheckBox:      A2CheckBox,
  Slider:        A2Slider,
  ChoicePicker:  A2ChoicePicker,
  MultipleChoice:A2ChoicePicker,  // alias
  DateTimeInput: A2DateTimeInput,
  Image:         A2Image,
  Icon:          A2Icon,
  Divider:       A2Divider,
  Card:          A2Card,
  Row:           A2Row,
  Column:        A2Column,
  List:          A2List,
  Modal:         A2Modal,
}
