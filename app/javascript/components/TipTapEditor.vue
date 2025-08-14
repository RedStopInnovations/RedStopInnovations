<template>
  <div class="tiptap-editor-container">
    <div
      ref="toolbarRef"
      class="tiptap-toolbar"
    ></div>
    <editor-content
      :editor="editor"
      class="tiptap-editor"
    />
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue';
import { Editor, EditorContent } from '@tiptap/vue-3';
import StarterKit from '@tiptap/starter-kit';

// Props
const props = defineProps({
  content: {
    type: String,
    default: ''
  },
  editable: {
    type: Boolean,
    default: true
  }
});

// Emits
const emit = defineEmits(['update:content', 'update:htmlContent']);

// State
const editor = ref(null);
const toolbarRef = ref(null);

// Initialize editor
function initializeEditor() {
  const initialContent = props.content ? JSON.parse(props.content) : '<p></p>';
  editor.value = new Editor({
    content: initialContent,
    extensions: [
      StarterKit
    ],
    editable: props.editable,
    onUpdate: ({ editor }) => {
      const json = editor.getJSON();
      const html = editor.getHTML();

      emit('update:content', JSON.stringify(json));
      emit('update:htmlContent', html);
    }
  });
}

// Helper functions for toolbar
function createButton(config) {
  const btn = document.createElement('button');
  btn.type = 'button';
  btn.innerHTML = config.icon;
  btn.title = config.title;
  btn.addEventListener('click', config.action);

  if (config.isActive) {
    const updateState = () => {
      btn.classList.toggle('is-active', config.isActive());
    };
    editor.value.on('selectionUpdate', updateState);
    editor.value.on('transaction', updateState);
    updateState();
  }

  return btn;
}

function createSelect(config) {
  const dropdown = document.createElement('div');
  dropdown.className = 'toolbar-dropdown dropdown';

  const button = document.createElement('button');
  button.className = 'btn btn-default dropdown-toggle';
  button.type = 'button';
  button.setAttribute('data-toggle', 'dropdown');
  button.setAttribute('aria-haspopup', 'true');
  button.setAttribute('aria-expanded', 'false');
  button.title = config.title;

  const buttonContent = document.createElement('span');
  if (config.icon) {
    buttonContent.innerHTML = config.icon;
  } else {
    buttonContent.textContent = config.options[0].label;
  }

  const caret = document.createElement('span');
  caret.className = 'caret';

  button.appendChild(buttonContent);
  button.appendChild(caret);

  const menu = document.createElement('ul');
  menu.className = 'dropdown-menu';
  menu.setAttribute('role', 'menu');

  config.options.forEach(option => {
    const li = document.createElement('li');
    li.setAttribute('role', 'presentation');

    const a = document.createElement('a');
    a.setAttribute('role', 'menuitem');
    a.setAttribute('tabindex', '-1');
    a.href = '#';
    a.textContent = option.label;
    a.setAttribute('data-value', option.value);

    a.addEventListener('click', (e) => {
      e.preventDefault();
      config.onChange(option.value);

      if (!config.icon) {
        buttonContent.textContent = option.label;
      }

      menu.querySelectorAll('li').forEach(item => item.classList.remove('active'));
      li.classList.add('active');
    });

    li.appendChild(a);
    menu.appendChild(li);
  });

  dropdown.appendChild(button);
  dropdown.appendChild(menu);

  if (config.getCurrentValue) {
    const updateValue = () => {
      const currentValue = config.getCurrentValue();
      const currentOption = config.options.find(opt => opt.value === currentValue) || config.options[0];

      if (!config.icon) {
        buttonContent.textContent = currentOption.label;
      }

      menu.querySelectorAll('li').forEach((li, index) => {
        li.classList.toggle('active', config.options[index].value === currentValue);
      });
    };
    editor.value.on('selectionUpdate', updateValue);
    editor.value.on('transaction', updateValue);
    updateValue();
  }

  return dropdown;
}

function createSeparator() {
  const separator = document.createElement('div');
  separator.className = 'toolbar-separator';
  return separator;
}

function createGroup(items) {
  const group = document.createElement('div');
  group.className = 'toolbar-group';
  items.forEach(item => group.appendChild(item));
  return group;
}

// Build toolbar (using only StarterKit + TextAlign + Underline)
function buildToolbar() {
  if (!toolbarRef.value || !editor.value) return;

  const toolbar = toolbarRef.value;
  toolbar.innerHTML = '';

  // Text formatting buttons (from StarterKit)
  const boldBtn = createButton({
    icon: '<i class="fa fa-bold"></i>',
    title: 'Bold',
    action: () => editor.value.chain().focus().toggleBold().run(),
    isActive: () => editor.value.isActive('bold')
  });

  const italicBtn = createButton({
    icon: '<i class="fa fa-italic"></i>',
    title: 'Italic',
    action: () => editor.value.chain().focus().toggleItalic().run(),
    isActive: () => editor.value.isActive('italic')
  });

  const strikeBtn = createButton({
    icon: '<i class="fa fa-strikethrough"></i>',
    title: 'Strikethrough',
    action: () => editor.value.chain().focus().toggleStrike().run(),
    isActive: () => editor.value.isActive('strike')
  });

  // Headings (from StarterKit)
  const heading1Btn = createButton({
    icon: '<i class="fa fa-header"></i> 1',
    title: 'Heading 1',
    action: () => editor.value.chain().focus().toggleHeading({ level: 1 }).run(),
    isActive: () => editor.value.isActive('heading', { level: 1 })
  });

  const heading2Btn = createButton({
    icon: '<i class="fa fa-header"></i> 2',
    title: 'Heading 2',
    action: () => editor.value.chain().focus().toggleHeading({ level: 2 }).run(),
    isActive: () => editor.value.isActive('heading', { level: 2 })
  });

  // Lists (from StarterKit)
  const bulletListBtn = createButton({
    icon: '<i class="fa fa-list-ul"></i>',
    title: 'Bullet List',
    action: () => editor.value.chain().focus().toggleBulletList().run(),
    isActive: () => editor.value.isActive('bulletList')
  });

  const orderedListBtn = createButton({
    icon: '<i class="fa fa-list-ol"></i>',
    title: 'Ordered List',
    action: () => editor.value.chain().focus().toggleOrderedList().run(),
    isActive: () => editor.value.isActive('orderedList')
  });

  // Blockquote (from StarterKit)
  const blockquoteBtn = createButton({
    icon: '<i class="fa fa-quote-left"></i>',
    title: 'Blockquote',
    action: () => editor.value.chain().focus().toggleBlockquote().run(),
    isActive: () => editor.value.isActive('blockquote')
  });

  // Code (from StarterKit)
  const codeBtn = createButton({
    icon: '<i class="fa fa-code"></i>',
    title: 'Inline Code',
    action: () => editor.value.chain().focus().toggleCode().run(),
    isActive: () => editor.value.isActive('code')
  });

  // History (from StarterKit)
  const undoBtn = createButton({
    icon: '<i class="fa fa-undo"></i>',
    title: 'Undo',
    action: () => editor.value.chain().focus().undo().run()
  });

  const redoBtn = createButton({
    icon: '<i class="fa fa-repeat"></i>',
    title: 'Redo',
    action: () => editor.value.chain().focus().redo().run()
  });

  // Assemble toolbar
  toolbar.appendChild(createGroup([undoBtn, redoBtn]));
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(createGroup([boldBtn, italicBtn, strikeBtn]));
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(createGroup([heading1Btn, heading2Btn]));
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(createGroup([bulletListBtn, orderedListBtn]));
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(createGroup([blockquoteBtn, codeBtn]));
}

// Watch for content changes from parent
watch(() => props.content, (newContent) => {
  if (editor.value && newContent !== JSON.stringify(editor.value.getJSON())) {
    try {
      const content = newContent ? JSON.parse(newContent) : '<p></p>';
      editor.value.commands.setContent(content);
    } catch (e) {
      editor.value.commands.setContent(newContent || '<p></p>');
    }
  }
});

// Watch for editable changes
watch(() => props.editable, (newEditable) => {
  if (editor.value) {
    editor.value.setEditable(newEditable);
  }
});

// Lifecycle
onMounted(() => {
  initializeEditor();

  // Wait a tick for editor to be ready, then build toolbar
  setTimeout(() => {
    buildToolbar();
  }, 100);
});

onBeforeUnmount(() => {
  if (editor.value) {
    editor.value.destroy();
  }
});

// Expose editor instance for parent components
defineExpose({
  editor,
  getJSON: () => editor.value?.getJSON(),
  getHTML: () => editor.value?.getHTML(),
  setContent: (content) => editor.value?.commands.setContent(content),
  focus: () => editor.value?.commands.focus()
});
</script>


<style>
.tiptap-editor-container {
  border: 1px solid #d1d5db;
  border-radius: 8px;
  overflow: hidden;

  .tiptap-toolbar {
    background: #f9fafb;
    border-bottom: 1px solid #d1d5db;
    padding: 8px 20px;
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    align-items: center;
  }

  .toolbar-group {
    display: flex;
    gap: 4px;
    align-items: center;
  }

  .toolbar-separator {
    width: 1px;
    height: 24px;
    background: #d1d5db;
    margin: 0 4px;
  }

  .tiptap-toolbar button {
    background: #fff;
    border: 1px solid #d1d5db;
    border-radius: 4px;
    padding: 6px 8px;
    cursor: pointer;
    font-size: 14px;
    transition: all 0.2s;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 32px;
    height: 32px;
  }

  .tiptap-toolbar button:hover {
    background: #f3f4f6;
    border-color: #9ca3af;
  }

  .tiptap-toolbar button.is-active {
    background: #3b82f6;
    color: white;
    border-color: #3b82f6;
  }

  .tiptap-toolbar select {
    background: #fff;
    border: 1px solid #d1d5db;
    border-radius: 4px;
    padding: 4px 8px;
    cursor: pointer;
    font-size: 14px;
    min-width: 120px;
    height: 32px;
  }

  .tiptap-toolbar select:hover {
    border-color: #9ca3af;
  }

  .tiptap-toolbar select:focus {
    outline: none;
    border-color: #3b82f6;
    box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.1);
  }

  /* Bootstrap Dropdown Styles */
  .toolbar-dropdown {
    position: relative;
    display: inline-block;
  }

  .toolbar-dropdown .btn {
    background: #fff;
    border: 1px solid #d1d5db;
    border-radius: 4px;
    padding: 6px 12px;
    cursor: pointer;
    font-size: 14px;
    height: 32px;
    display: inline-flex;
    align-items: center;
    justify-content: space-between;
    text-align: left;
    color: #374151;
  }

  .toolbar-dropdown .btn:hover {
    background: #f3f4f6;
    border-color: #9ca3af;
  }

  .toolbar-dropdown .btn:focus {
    outline: none;
    border-color: #3b82f6;
    box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.1);
  }

  .toolbar-dropdown .caret {
    margin-left: 8px;
  }

  .toolbar-dropdown .dropdown-menu {
    min-width: 120px;
    font-size: 14px;
  }

  .toolbar-dropdown .dropdown-menu>li>a {
    padding: 6px 12px;
    font-size: 14px;
  }

  .toolbar-dropdown .dropdown-menu>li.active>a {
    background-color: #3b82f6;
    color: white;
  }

  .color-picker {
    position: relative;
    display: inline-block;
  }

  .color-picker button {
    width: 32px;
    height: 32px;
    border: 1px solid #d1d5db;
    border-radius: 4px;
    cursor: pointer;
    padding: 0;
    background: transparent;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .color-picker button:hover {
    background: #f3f4f6;
    border-color: #9ca3af;
  }

  .color-picker-popup {
    position: absolute;
    top: 100%;
    left: 0;
    background: white;
    border: 1px solid #d1d5db;
    border-radius: 8px;
    padding: 12px;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    z-index: 1000;
    min-width: 200px;
    display: none;
  }

  .color-picker-popup.show {
    display: block;
  }

  .color-picker-title {
    font-size: 12px;
    font-weight: bold;
    margin-bottom: 8px;
    color: #374151;
  }

  .color-swatches {
    display: grid;
    grid-template-columns: repeat(6, 1fr);
    gap: 4px;
    margin-bottom: 8px;
  }

  .color-swatch {
    width: 24px;
    height: 24px;
    border: 1px solid #d1d5db;
    border-radius: 4px;
    cursor: pointer;
    transition: transform 0.1s;
  }

  .color-swatch:hover {
    transform: scale(1.1);
    border-color: #374151;
  }

  .color-picker-reset {
    width: 100%;
    padding: 6px;
    background: #f3f4f6;
    border: 1px solid #d1d5db;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
    margin-top: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    height: 32px;
  }

  .color-picker-reset:hover {
    background: #fee2e2;
    border-color: #dc2626;
    color: #991b1b;
  }

  .tiptap-editor {
    padding: 20px;
    min-height: 200px;
    outline: none;
  }

  .tiptap-editor > .tiptap {
    outline: none;
  }

  .tiptap-editor :deep(.ProseMirror) {
    outline: none;
    font-family: Arial, sans-serif;
    font-size: 14px;
    line-height: 1.5;
  }

  .tiptap-editor :deep(h1) {
    font-size: 2em;
    font-weight: bold;
    margin: 0.67em 0;
  }

  .tiptap-editor :deep(h2) {
    font-size: 1.5em;
    font-weight: bold;
    margin: 0.75em 0;
  }

  .tiptap-editor :deep(h3) {
    font-size: 1.17em;
    font-weight: bold;
    margin: 0.83em 0;
  }

  .tiptap-editor :deep(h4) {
    font-size: 1em;
    font-weight: bold;
    margin: 1.12em 0;
  }

  .tiptap-editor :deep(ul),
  .tiptap-editor :deep(ol) {
    margin: 1em 0;
    padding-left: 2em;
  }

  .tiptap-editor :deep(blockquote) {
    border-left: 4px solid #d1d5db;
    padding-left: 1em;
    margin: 1em 0;
    font-style: italic;
    color: #6b7280;
  }

  .tiptap-editor :deep(code) {
    background: #f3f4f6;
    padding: 2px 4px;
    border-radius: 3px;
    font-family: monospace;
  }

  .tiptap-editor :deep(pre) {
    background: #f3f4f6;
    padding: 1em;
    border-radius: 6px;
    overflow-x: auto;
    margin: 1em 0;
  }

  .tiptap-editor :deep(pre code) {
    background: none;
    padding: 0;
  }

  .tiptap-editor :deep(img) {
    max-width: 100%;
    height: auto;
    border-radius: 4px;
  }

  .tiptap-editor :deep(table) {
    border-collapse: collapse;
    width: 100%;
    margin: 1em 0;
  }

  .tiptap-editor :deep(table td),
  .tiptap-editor :deep(table th) {
    border: 1px solid #d1d5db;
    padding: 8px 12px;
    text-align: left;
  }

  .tiptap-editor :deep(table th) {
    background: #f9fafb;
    font-weight: bold;
  }

  .tiptap-editor :deep(ul[data-type="taskList"]) {
    list-style: none;
    padding-left: 0;
  }

  .tiptap-editor :deep(ul[data-type="taskList"] li) {
    display: flex;
    align-items: flex-start;
    margin: 0.25em 0;
  }

  .tiptap-editor :deep(ul[data-type="taskList"] li>label) {
    margin-right: 0.5em;
    user-select: none;
  }

  .tiptap-editor :deep(ul[data-type="taskList"] li>div) {
    flex: 1;
  }

  /* Drag Handle Styles */
  .tiptap-editor :deep(.js-drag-handle) {
    position: absolute;
    left: -1.5rem;
    top: 0;
    cursor: grab;
    padding: 0.25rem;
    color: #9ca3af;
  }

  .tiptap-editor :deep(.js-drag-handle):hover {
    background-color: #eeeeee;
  }

  .tiptap-editor :deep(.js-drag-handle):active {
    cursor: grabbing;
  }

  .tiptap-editor :deep(.ProseMirror):hover .drag-handle {
    opacity: 0.5;
  }

  .tiptap-editor :deep(.js-drag-handle svg) {
    width: 1rem;
    height: 1rem;
  }
}
</style>