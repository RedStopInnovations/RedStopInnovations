import { Node, mergeAttributes } from '@tiptap/core';

// Custom MultipleChoice extension
export const MultipleChoiceList = Node.create({
  name: 'multipleChoice',

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

            // Find the multipleChoice node
            for (let i = $pos.depth; i >= 0; i--) {
              const node = $pos.node(i);
              if (node.type.name === 'multipleChoice') {
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

export const MultipleChoiceItem = Node.create({
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

          // Find the multipleChoice parent
          for (let depth = $pos.depth; depth >= 0; depth--) {
            const node = $pos.node(depth);
            if (node.type.name === 'multipleChoice') {
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

          // Find the multipleChoice parent
          let list = null;
          let listDepth = -1;
          for (let depth = $pos.depth; depth >= 0; depth--) {
            const node = $pos.node(depth);
            if (node.type.name === 'multipleChoice') {
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

              // Find the multipleChoice parent
              for (let depth = $pos.depth; depth >= 0; depth--) {
                const node = $pos.node(depth);
                if (node.type.name === 'multipleChoice' && node.attrs.id) {
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
});
