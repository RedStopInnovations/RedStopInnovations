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
import TextAlign from '@tiptap/extension-text-align';
import Underline from '@tiptap/extension-underline';
import Color from '@tiptap/extension-color';
import Highlight from '@tiptap/extension-highlight';
import FontFamily from '@tiptap/extension-font-family';
import Link from '@tiptap/extension-link';
import Image from '@tiptap/extension-image';
import { Table } from '@tiptap/extension-table';
import { TableRow } from '@tiptap/extension-table-row';
import { TableCell } from '@tiptap/extension-table-cell';
import { TableHeader } from '@tiptap/extension-table-header';
import { TaskList } from '@tiptap/extension-task-list';
import { TaskItem } from '@tiptap/extension-task-item';
import { TextStyle, FontSize } from '@tiptap/extension-text-style';

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
      StarterKit,
      TextStyle,
      FontSize,
      TextAlign.configure({
        types: ['heading', 'paragraph'],
      }),
      Underline,
      Color.configure({ types: [TextStyle.name] }),
      Highlight.configure({ multicolor: true }),
      FontFamily.configure({
        types: ['textStyle'],
      }),
      Link.configure({
        openOnClick: false,
      }),
      Image,
      Table.configure({
        resizable: true,
      }),
      TableRow,
      TableHeader,
      TableCell,
      TaskList,
      TaskItem.configure({
        nested: true,
      }),
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
  btn.className = 'btn btn-white';
  btn.innerHTML = config.icon;
  btn.title = config.title;
  btn.addEventListener('click', config.action);

  if (config.isActive) {
    const updateState = () => {
      btn.classList.toggle('active', config.isActive());
    };
    editor.value.on('selectionUpdate', updateState);
    editor.value.on('transaction', updateState);
    updateState();
  }

  return btn;
}

function createDropdown(config) {
  const dropdown = document.createElement('div');
  dropdown.className = 'btn-group dropdown';

  const button = document.createElement('button');
  button.className = 'btn btn-white btn-sm dropdown-toggle';
  button.type = 'button';
  button.setAttribute('data-toggle', 'dropdown');
  button.setAttribute('aria-haspopup', 'true');
  button.setAttribute('aria-expanded', 'false');
  button.title = config.title;

  const buttonContent = document.createElement('span');
  if (config.icon) {
    buttonContent.innerHTML = config.icon + ' ';
  }

  const label = document.createElement('span');
  label.textContent = config.defaultLabel || config.options[0].label;

  const caret = document.createElement('span');
  caret.className = 'caret';

  button.appendChild(buttonContent);
  button.appendChild(label);
  button.appendChild(document.createTextNode(' '));
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

    if (option.style) {
      Object.assign(a.style, option.style);
    }

    a.addEventListener('click', (e) => {
      e.preventDefault();
      config.onChange(option.value);

      if (!config.keepLabel) {
        label.textContent = option.label;
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
      const currentOption = config.options.find(opt => opt.value === currentValue);

      if (currentOption && !config.keepLabel) {
        label.textContent = currentOption.label;
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

function createColorPicker(config) {
  const container = document.createElement('div');
  container.className = 'btn-group dropdown color-picker';

  const button = document.createElement('button');
  button.className = 'btn btn-white btn-sm dropdown-toggle';
  button.type = 'button';
  button.setAttribute('data-toggle', 'dropdown');
  button.setAttribute('aria-haspopup', 'true');
  button.setAttribute('aria-expanded', 'false');
  button.innerHTML = config.icon;
  button.title = config.title;

  const menu = document.createElement('div');
  menu.className = 'dropdown-menu color-picker-dropdown';

  const colors = [
    '#000000', '#333333', '#666666', '#999999', '#cccccc', '#ffffff',
    '#ff0000', '#ff6666', '#ffcccc', '#00ff00', '#66ff66', '#ccffcc',
    '#0000ff', '#6666ff', '#ccccff', '#ffff00', '#ffff66', '#ffffcc',
    '#ff00ff', '#ff66ff', '#ffccff', '#00ffff', '#66ffff', '#ccffff'
  ];

  colors.forEach(color => {
    const colorBtn = document.createElement('button');
    colorBtn.type = 'button';
    colorBtn.className = 'color-swatch';
    colorBtn.style.backgroundColor = color;
    colorBtn.title = color;
    colorBtn.addEventListener('click', (e) => {
      e.preventDefault();
      config.onChange(color);
    });
    menu.appendChild(colorBtn);
  });

  const clearBtn = document.createElement('button');
  clearBtn.type = 'button';
  clearBtn.className = 'btn btn-sm btn-white color-clear';
  clearBtn.textContent = 'Clear';
  clearBtn.addEventListener('click', (e) => {
    e.preventDefault();
    config.onClear();
  });
  menu.appendChild(clearBtn);

  container.appendChild(button);
  container.appendChild(menu);

  return container;
}

function createSeparator() {
  const separator = document.createElement('div');
  separator.className = 'toolbar-separator';
  return separator;
}

function createGroup(items) {
  const group = document.createElement('div');
  group.className = 'btn-group toolbar-group';
  items.forEach(item => {
    if (item.classList.contains('btn-group') || item.classList.contains('dropdown')) {
      group.appendChild(item);
    } else {
      group.appendChild(item);
    }
  });
  return group;
}

// Build comprehensive toolbar
function buildToolbar() {
  if (!toolbarRef.value || !editor.value) return;

  const toolbar = toolbarRef.value;
  toolbar.innerHTML = '';

  // Group 1: Undo/Redo
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

  // Group 2: Heading Dropdown
  const headingDropdown = createDropdown({
    icon: '<i class="fa fa-header"></i>',
    title: 'Heading',
    defaultLabel: 'Normal',
    options: [
      { label: 'Normal', value: 'paragraph' },
      { label: 'Heading 1', value: 'h1' },
      { label: 'Heading 2', value: 'h2' },
      { label: 'Heading 3', value: 'h3' },
      { label: 'Heading 4', value: 'h4' }
    ],
    onChange: (value) => {
      if (value === 'paragraph') {
        editor.value.chain().focus().setParagraph().run();
      } else {
        const level = parseInt(value.replace('h', ''));
        editor.value.chain().focus().toggleHeading({ level }).run();
      }
    },
    getCurrentValue: () => {
      if (editor.value.isActive('heading', { level: 1 })) return 'h1';
      if (editor.value.isActive('heading', { level: 2 })) return 'h2';
      if (editor.value.isActive('heading', { level: 3 })) return 'h3';
      if (editor.value.isActive('heading', { level: 4 })) return 'h4';
      return 'paragraph';
    }
  });

  // Group 3: Font Family Dropdown
  const fontFamilyDropdown = createDropdown({
    icon: '<i class="fa fa-font"></i>',
    title: 'Font Family',
    defaultLabel: 'Arial',
    keepLabel: true,
    options: [
      { label: 'Arial', value: 'Arial, sans-serif' },
      { label: 'Times New Roman', value: 'Times New Roman, serif' },
      { label: 'Helvetica', value: 'Helvetica, sans-serif' },
      { label: 'Georgia', value: 'Georgia, serif' },
      { label: 'Verdana', value: 'Verdana, sans-serif' },
      { label: 'Comic Sans MS', value: 'Comic Sans MS, cursive' },
      { label: 'Courier New', value: 'Courier New, monospace' }
    ],
    onChange: (value) => {
      editor.value.chain().focus().setFontFamily(value).run();
    }
  });

  // Group 4: Font Size Dropdown
  const fontSizeDropdown = createDropdown({
    icon: '<i class="fa fa-text-height"></i>',
    title: 'Font Size',
    defaultLabel: '14px',
    keepLabel: true,
    options: [
      { label: '8px', value: '8px' },
      { label: '9px', value: '9px' },
      { label: '10px', value: '10px' },
      { label: '11px', value: '11px' },
      { label: '12px', value: '12px' },
      { label: '14px', value: '14px' },
      { label: '18px', value: '18px' },
      { label: '24px', value: '24px' },
      { label: '30px', value: '30px' },
      { label: '36px', value: '36px' }
    ],
    onChange: (value) => {
      // Use TextStyle extension with fontSize attribute
      editor.value.chain().focus().setFontSize(value).run();
    }
  });

  // Group 5: Text Formatting
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

  const underlineBtn = createButton({
    icon: '<i class="fa fa-underline"></i>',
    title: 'Underline',
    action: () => editor.value.chain().focus().toggleUnderline().run(),
    isActive: () => editor.value.isActive('underline')
  });

  const strikeBtn = createButton({
    icon: '<i class="fa fa-strikethrough"></i>',
    title: 'Strikethrough',
    action: () => editor.value.chain().focus().toggleStrike().run(),
    isActive: () => editor.value.isActive('strike')
  });

  const colorPicker = createColorPicker({
    icon: '<i class="fa fa-font"></i>',
    title: 'Text Color',
    onChange: (color) => editor.value.chain().focus().setColor(color).run(),
    onClear: () => editor.value.chain().focus().unsetColor().run()
  });

  const highlightPicker = createColorPicker({
    icon: '<i class="fa fa-paint-brush"></i>',
    title: 'Highlight Color',
    onChange: (color) => editor.value.chain().focus().toggleHighlight({ color }).run(),
    onClear: () => editor.value.chain().focus().unsetHighlight().run()
  });

  // Group 6: Lists
  const listDropdown = createDropdown({
    icon: '<i class="fa fa-list"></i>',
    title: 'Lists',
    defaultLabel: 'List',
    keepLabel: true,
    options: [
      { label: 'Bullet List', value: 'bulletList' },
      { label: 'Ordered List', value: 'orderedList' },
      { label: 'Task List', value: 'taskList' }
    ],
    onChange: (value) => {
      if (value === 'bulletList') {
        editor.value.chain().focus().toggleBulletList().run();
      } else if (value === 'orderedList') {
        editor.value.chain().focus().toggleOrderedList().run();
      } else if (value === 'taskList') {
        editor.value.chain().focus().toggleTaskList().run();
      }
    }
  });

  // Group 7: Media & Structure
  const linkBtn = createButton({
    icon: '<i class="fa fa-link"></i>',
    title: 'Link',
    action: () => {
      const url = window.prompt('URL');
      if (url) {
        editor.value.chain().focus().setLink({ href: url }).run();
      }
    },
    isActive: () => editor.value.isActive('link')
  });

  const imageBtn = createButton({
    icon: '<i class="fa fa-image"></i>',
    title: 'Image',
    action: () => {
      const url = window.prompt('Image URL');
      if (url) {
        editor.value.chain().focus().setImage({ src: url }).run();
      }
    }
  });

  const tableBtn = createButton({
    icon: '<i class="fa fa-table"></i>',
    title: 'Table',
    action: () => {
      editor.value.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run();
    }
  });

  const blockquoteBtn = createButton({
    icon: '<i class="fa fa-quote-left"></i>',
    title: 'Blockquote',
    action: () => editor.value.chain().focus().toggleBlockquote().run(),
    isActive: () => editor.value.isActive('blockquote')
  });

  // Group 8: Alignment
  const alignDropdown = createDropdown({
    icon: '<i class="fa fa-align-left"></i>',
    title: 'Text Align',
    defaultLabel: 'Left',
    options: [
      { label: 'Left', value: 'left' },
      { label: 'Center', value: 'center' },
      { label: 'Right', value: 'right' },
      { label: 'Justify', value: 'justify' }
    ],
    onChange: (value) => {
      editor.value.chain().focus().setTextAlign(value).run();
    },
    getCurrentValue: () => {
      if (editor.value.isActive({ textAlign: 'center' })) return 'center';
      if (editor.value.isActive({ textAlign: 'right' })) return 'right';
      if (editor.value.isActive({ textAlign: 'justify' })) return 'justify';
      return 'left';
    }
  });

  // Group 9: Clear Format
  const clearFormatBtn = createButton({
    icon: '<i class="fa fa-eraser"></i>',
    title: 'Clear Format',
    action: () => editor.value.chain().focus().clearNodes().unsetAllMarks().run()
  });

  // Assemble toolbar
  toolbar.appendChild(createGroup([undoBtn, redoBtn]));
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(headingDropdown);
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(fontFamilyDropdown);
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(fontSizeDropdown);
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(createGroup([boldBtn, italicBtn, underlineBtn, strikeBtn]));
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(colorPicker);
  toolbar.appendChild(highlightPicker);
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(listDropdown);
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(createGroup([linkBtn, imageBtn, tableBtn, blockquoteBtn]));
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(alignDropdown);
  toolbar.appendChild(createSeparator());
  toolbar.appendChild(clearFormatBtn);

  // Add Bootstrap dropdown functionality
  setupDropdownToggles();
}

// Setup Bootstrap 3 dropdown functionality
function setupDropdownToggles() {
  const dropdowns = toolbarRef.value.querySelectorAll('.dropdown');

  dropdowns.forEach(dropdown => {
    const toggle = dropdown.querySelector('.dropdown-toggle');
    const menu = dropdown.querySelector('.dropdown-menu');

    if (toggle && menu) {
      toggle.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();

        // Close other dropdowns
        dropdowns.forEach(otherDropdown => {
          if (otherDropdown !== dropdown) {
            otherDropdown.classList.remove('open');
          }
        });

        // Toggle current dropdown
        dropdown.classList.toggle('open');
      });
    }
  });

  // Close dropdowns when clicking outside
  document.addEventListener('click', (e) => {
    if (!toolbarRef.value.contains(e.target)) {
      dropdowns.forEach(dropdown => {
        dropdown.classList.remove('open');
      });
    }
  });
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


<style lang="scss">
.tiptap-editor-container {
  border: 1px solid #d1d5db;
  border-radius: 4px;
  overflow: hidden;

  .tiptap-toolbar {
    background: #f9fafb;
    border-bottom: 1px solid #d1d5db;
    padding: 8px 12px;
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    align-items: center;
  }

  .toolbar-group {
    display: flex;
    gap: 2px;
    align-items: center;
  }

  .toolbar-separator {
    width: 1px;
    height: 24px;
    background: #d1d5db;
    margin: 0 4px;
  }

  /* Dropdown Menu Visibility */
  .dropdown .dropdown-menu {
    display: none;
  }

  .dropdown.open .dropdown-menu {
    display: block;
  }

  /* Toolbar Button Styles */
  .tiptap-toolbar .btn {
    padding: 5px 10px;
  }

  /* Color Picker Styles */
  .color-picker-dropdown {
    padding: 8px;
    display: grid;
    grid-template-columns: repeat(6, 1fr);
    gap: 4px;
    min-width: 180px;
  }

  .color-swatch {
    width: 20px;
    height: 20px;
    border: 1px solid #ccc;
    border-radius: 2px;
    cursor: pointer;
    transition: transform 0.1s;
  }

  .color-swatch:hover {
    transform: scale(1.1);
    border-color: #333;
  }

  .color-clear {
    grid-column: 1 / -1;
    margin-top: 4px;
    width: 100%;
  }

  .tiptap-editor {
    padding: 20px;
    min-height: 200px;
    outline: none;
  }

  .tiptap-editor>.tiptap {
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

  /* Text alignment classes */
  .tiptap-editor :deep(.has-text-align-left) {
    text-align: left;
  }

  .tiptap-editor :deep(.has-text-align-center) {
    text-align: center;
  }

  .tiptap-editor :deep(.has-text-align-right) {
    text-align: right;
  }

  .tiptap-editor :deep(.has-text-align-justify) {
    text-align: justify;
  }

  /* Table styling */
  .tiptap-editor {
    table {
      border-collapse: collapse;
      margin: 0;
      overflow: hidden;
      table-layout: fixed;
      width: 100%;

      td,
      th {
        border: 1px solid #ddd;
        box-sizing: border-box;
        min-width: 1em;
        padding: 6px 8px;
        position: relative;
        vertical-align: top
      }

      td>*,
      th>* {
        margin-bottom: 0
      }

      th {
        background-color: #f4f4f4;
        font-weight: 600;
        text-align: left
      }
    }
  }

  /* TaskList styling */

  ul[data-type=taskList] {
    padding-left: .25em;

    li:not(:has(>p:first-child)) {
      list-style-type: none;
    }

    [contenteditable="false"] {
      white-space: normal;
    }

    li {
      display: flex;
      flex-direction: row;
      align-items: flex-start;

      label {
        position: relative;
        margin-bottom: 0;
        padding-right: .5rem;

        span {
          display: block;
          width: 1em;
          height: 1em;
          position: relative;
          cursor: pointer;
        }
      }

      > div {
        p {
          margin: 0;
        }
      }
    }
  }

}
</style>