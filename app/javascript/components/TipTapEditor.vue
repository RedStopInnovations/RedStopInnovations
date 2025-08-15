<template>
  <div class="tiptap-editor-container">
    <div
      ref="toolbarRef"
      class="tiptap-toolbar"
    ></div>

    <template v-if="editor">
      <DragHandle :editor="editor">
        <div class="custom-drag-handle"></div>
      </DragHandle>
    </template>

    <editor-content
      :editor="editor"
      class="tiptap-editor"
    />
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue';
import { Editor, EditorContent } from '@tiptap/vue-3';
import Text from '@tiptap/extension-text';
import Document from '@tiptap/extension-document'
import Paragraph from '@tiptap/extension-paragraph'
import TextAlign from '@tiptap/extension-text-align';
import Color from '@tiptap/extension-color';
import Heading from '@tiptap/extension-heading';
import Highlight from '@tiptap/extension-highlight';
import { BulletList, ListItem, OrderedList, TaskList, TaskItem, ListKeymap } from '@tiptap/extension-list';
import FontFamily from '@tiptap/extension-font-family';
import Link from '@tiptap/extension-link';
import Image from '@tiptap/extension-image';
import { TableKit } from '@tiptap/extension-table';
import { TextStyle, FontSize } from '@tiptap/extension-text-style';
import { DragHandle } from '@tiptap/extension-drag-handle-vue-3';
import NodeRange from '@tiptap/extension-node-range';
import HorizontalRule from '@tiptap/extension-horizontal-rule';
import Bold from '@tiptap/extension-bold';
import Italic from '@tiptap/extension-italic';
import Strike from '@tiptap/extension-strike';
import Underline from '@tiptap/extension-underline';
import { Dropcursor, UndoRedo, Placeholder, Gapcursor, TrailingNode } from '@tiptap/extensions';
import { Node, mergeAttributes } from '@tiptap/core';

// Custom MultipleChoice extension
const MultipleChoiceList = Node.create({
  name: 'multipleChoiceList',

  group: 'block list',

  content: 'multipleChoiceItem+',

  addAttributes() {
    return {
      id: {
        default: null,
        parseHTML: element => element.getAttribute('data-id'),
        renderHTML: attributes => ({
          'data-id': attributes.id,
        }),
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'ul[data-type="multipleChoice"]',
      },
    ];
  },

  renderHTML({ HTMLAttributes, node }) {
    // Ensure the list has a consistent ID
    let id = node.attrs.id;
    if (!id) {
      id = `choice-${Math.random().toString(36).substr(2, 9)}-${Date.now()}`;
      // Update the node attributes to include the generated ID
      node.attrs.id = id;
    }
    return [
      'ul',
      mergeAttributes(HTMLAttributes, {
        'data-id': id,
        'data-type': 'multipleChoice',
        'class': 'multiple-choice'
      }),
      0,
    ];
  },

  addCommands() {
    return {
      toggleMultipleChoiceList: () => ({ commands, tr, state }) => {
        const { selection } = state;
        const { $from } = selection;

        // Generate a unique ID for the new list
        const listId = `choice-${Math.random().toString(36).substr(2, 9)}-${Date.now()}`;

        // Store the ID so items can use it
        const result = commands.toggleList(this.name, 'multipleChoiceItem');

        // Update the list with the ID after creation
        if (result) {
          setTimeout(() => {
            const pos = selection.from;
            const $pos = state.doc.resolve(pos);
            let listNode = null;
            let listPos = null;

            // Find the multipleChoiceList node
            for (let i = $pos.depth; i >= 0; i--) {
              const node = $pos.node(i);
              if (node.type.name === 'multipleChoiceList') {
                listNode = node;
                listPos = $pos.start(i);
                break;
              }
            }

            if (listNode && !listNode.attrs.id) {
              tr.setNodeMarkup(listPos, undefined, {
                ...listNode.attrs,
                id: listId,
              });
            }
          }, 0);
        }

        return result;
      },
    };
  },
});

const MultipleChoiceItem = Node.create({
  name: 'multipleChoiceItem',

  content: 'paragraph block*',

  defining: true,

  addAttributes() {
    return {
      id: {
        default: null,
        parseHTML: element => element.getAttribute('data-id'),
        renderHTML: attributes => ({
          'data-id': attributes.id,
        }),
      },
      checked: {
        default: false,
        keepOnSplit: false,
        parseHTML: element => element.getAttribute('data-checked') === 'true',
        renderHTML: attributes => ({
          'data-checked': attributes.checked,
        }),
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'li[data-id]',
        priority: 51,
      },
    ];
  },

  renderHTML({ node, HTMLAttributes }) {
    const id = node.attrs.id || `item-${Math.random().toString(36).substr(2, 9)}-${Date.now()}`;
    const radioAttrs = {
      type: 'radio',
      name: 'placeholder-name', // This will be replaced by the list's data-id
    };

    // Add checked attribute if the item is checked
    if (node.attrs.checked) {
      radioAttrs.checked = 'checked';
    }

    return [
      'li',
      mergeAttributes(HTMLAttributes, {
        'data-id': id,
        'data-checked': node.attrs.checked
      }),
      [
        'label',
        [
          'input',
          radioAttrs,
        ],
        ['span'],
      ],
      ['div', 0],
    ];
  },

  addNodeView() {
    return ({ node, HTMLAttributes, getPos, editor }) => {
      const itemId = node.attrs.id || `item-${Math.random().toString(36).substr(2, 9)}-${Date.now()}`;

      const listItem = document.createElement('li');
      listItem.setAttribute('data-id', itemId);
      listItem.setAttribute('data-checked', node.attrs.checked);

      const label = document.createElement('label');
      const radioInput = document.createElement('input');
      radioInput.type = 'radio';

      // Get the parent list's data-id for the radio name
      let listId = null;
      if (typeof getPos === 'function') {
        try {
          const pos = getPos();
          const $pos = editor.state.doc.resolve(pos);

          // Find the multipleChoiceList parent
          for (let depth = $pos.depth; depth >= 0; depth--) {
            const node = $pos.node(depth);
            if (node.type.name === 'multipleChoiceList') {
              listId = node.attrs.id;

              // If no ID exists, generate one and update the list
              if (!listId) {
                listId = `choice-${Math.random().toString(36).substr(2, 9)}-${Date.now()}`;
                const listPos = $pos.start(depth);
                const tr = editor.state.tr.setNodeMarkup(listPos, undefined, {
                  ...node.attrs,
                  id: listId,
                });
                editor.view.dispatch(tr);
              }
              break;
            }
          }
        } catch (e) {
          console.warn('Could not get parent list for radio button name:', e);
        }
      }

      // Fallback if we couldn't get the list ID
      if (!listId) {
        listId = `choice-${Math.random().toString(36).substr(2, 9)}-${Date.now()}`;
      }

      radioInput.name = listId;
      radioInput.checked = node.attrs.checked;

      radioInput.addEventListener('change', () => {
        if (typeof getPos === 'function') {
          const pos = getPos();
          const $pos = editor.state.doc.resolve(pos);

          // Find the multipleChoiceList parent
          let list = null;
          let listDepth = -1;
          for (let depth = $pos.depth; depth >= 0; depth--) {
            const node = $pos.node(depth);
            if (node.type.name === 'multipleChoiceList') {
              list = node;
              listDepth = depth;
              break;
            }
          }

          if (list) {
            const tr = editor.state.tr;

            // Find the parent list element in the DOM to update all siblings
            const parentListElement = listItem.closest('ul[data-type="multipleChoice"]');

            // First, uncheck all items in this list
            list.forEach((child, offset) => {
              if (child.type.name === 'multipleChoiceItem' && child.attrs.checked) {
                const childPos = $pos.start(listDepth) + offset + 1;
                tr.setNodeMarkup(childPos, undefined, {
                  ...child.attrs,
                  checked: false,
                });

                // Update DOM for unchecked siblings
                if (parentListElement) {
                  const siblingItems = parentListElement.querySelectorAll('li[data-id]');
                  siblingItems.forEach(item => {
                    if (item !== listItem) {
                      item.setAttribute('data-checked', 'false');
                      const siblingRadio = item.querySelector('input[type="radio"]');
                      if (siblingRadio) {
                        siblingRadio.checked = false;
                      }
                    }
                  });
                }
              }
            });

            // Then check the current item
            tr.setNodeMarkup(pos, undefined, {
              ...node.attrs,
              checked: radioInput.checked,
            });

            // Update the DOM immediately for current item
            listItem.setAttribute('data-checked', radioInput.checked);

            editor.view.dispatch(tr);
          }
        }
      });

      const span = document.createElement('span');
      const contentDiv = document.createElement('div');

      label.appendChild(radioInput);
      label.appendChild(span);
      listItem.appendChild(label);
      listItem.appendChild(contentDiv);

      return {
        dom: listItem,
        contentDOM: contentDiv,
        update: (updatedNode) => {
          if (updatedNode.type !== node.type) {
            return false;
          }
          listItem.setAttribute('data-checked', updatedNode.attrs.checked);
          radioInput.checked = updatedNode.attrs.checked;

          // Update radio button name if needed
          if (typeof getPos === 'function') {
            try {
              const pos = getPos();
              const $pos = editor.state.doc.resolve(pos);

              // Find the multipleChoiceList parent
              for (let depth = $pos.depth; depth >= 0; depth--) {
                const node = $pos.node(depth);
                if (node.type.name === 'multipleChoiceList' && node.attrs.id) {
                  radioInput.name = node.attrs.id;
                  break;
                }
              }
            } catch (e) {
              // Ignore errors in update
            }
          }

          return true;
        },
      };
    };
  },

  addKeyboardShortcuts() {
    const shortcuts = {
      Enter: () => this.editor.commands.splitListItem('multipleChoiceItem'),
      'Shift-Tab': () => this.editor.commands.liftListItem('multipleChoiceItem'),
    };

    return shortcuts;
  },
});// Props
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
      Document,
      Paragraph,
      TextStyle,
      BulletList,
      OrderedList,
      ListItem,
      ListKeymap,
      Heading,
      Text,
      FontSize,
      HorizontalRule,
      TextAlign.configure({
        types: ['heading', 'paragraph'],
      }),
      Bold,
      Italic,
      Underline,
      Strike,
      Color.configure({ types: [TextStyle.name] }),
      Highlight.configure({ multicolor: true }),
      FontFamily.configure({
        types: ['textStyle'],
      }),
      Link.configure({
        openOnClick: false,
      }),
      Image,
      TaskList,
      TaskItem.configure({
        nested: true,
      }),
      MultipleChoiceList,
      MultipleChoiceItem,
      NodeRange.configure({
        key: null,
      }),
      Placeholder.configure({
        placeholder: 'Type something...'
      }),
      TableKit.configure({
        table: { resizable: true },
      }),
      Gapcursor,
      TrailingNode,
      Dropcursor,
      UndoRedo
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
      { label: 'Task List', value: 'taskList' },
      { label: 'Multiple Choice', value: 'multipleChoiceList' }
    ],
    onChange: (value) => {
      if (value === 'bulletList') {
        editor.value.chain().focus().toggleBulletList().run();
      } else if (value === 'orderedList') {
        editor.value.chain().focus().toggleOrderedList().run();
      } else if (value === 'taskList') {
        editor.value.chain().focus().toggleTaskList().run();
      } else if (value === 'multipleChoiceList') {
        editor.value.chain().focus().toggleMultipleChoiceList().run();
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
::selection {
  background-color: #7fc5e250;
}

.ProseMirror-noderangeselection {
  *::selection {
    background: transparent;
  }

  * {
    caret-color: transparent;
  }
}

.ProseMirror-selectednode,
.ProseMirror-selectednoderange {
  position: relative;

  &::before {
    position: absolute;
    pointer-events: none;
    z-index: -1;
    content: '';
    top: -0.25rem;
    left: -0.25rem;
    right: -0.25rem;
    bottom: -0.25rem;
    background-color: #70cff850;
    border-radius: 0.2rem;
  }
}

.custom-drag-handle {
  &::after {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 1.25rem;
    height: 1.5rem;
    content: '⠿';
    font-weight: 700;
    cursor: grab;
    background: #0d0d0d10;
    color: #0d0d0d50;
    border-radius: 0.25rem;
  }
}

.tiptap-editor-container {
  border: 1px solid #d1d5db;
  border-radius: 4px;

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
        vertical-align: top;
      }

      td>*,
      th>* {
        margin-bottom: 0;
      }

      th {
        background-color: #f4f4f4;
        font-weight: 600;
        text-align: left;
      }

      .selectedCell:after {
        background: var(--gray-2);
        content: '';
        left: 0;
        right: 0;
        top: 0;
        bottom: 0;
        pointer-events: none;
        position: absolute;
        z-index: 2;
      }

      .column-resize-handle {
        background-color: var(--purple);
        bottom: -2px;
        pointer-events: none;
        position: absolute;
        right: -2px;
        top: 0;
        width: 4px;
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

      >div {
        p {
          margin: 0;
        }
      }
    }
  }

  /* MultipleChoice styling */
  ul[data-type="multipleChoice"],
  ul.multiple-choice {
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

        input[type="radio"] {
          margin-right: 0.5rem;
          cursor: pointer;
        }

        span {
          display: none; // Hide the span since we're using actual radio buttons
        }
      }

      >div {
        p {
          margin: 0;
        }
      }
    }
  }

  /* Placeholder. only for the first line in an empty editor */
  p.is-editor-empty:first-child::before {
    color: #adb5bd;
    content: attr(data-placeholder);
    float: left;
    height: 0;
    pointer-events: none;
  }

  .tableWrapper {
    margin: 1.5rem 0;
    overflow-x: auto;
  }

  .resize-cursor {
    cursor: ew-resize;
    cursor: col-resize;
  }
}
</style>