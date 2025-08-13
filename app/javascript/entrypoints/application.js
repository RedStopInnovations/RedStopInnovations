// Vite ⚡️ Rails - Modern JavaScript for Dashboard
console.log('Vite ⚡️ Rails')

// Import CSS
import './application.css'

// Vue 3 Setup for modern dashboard components
import { createApp } from 'vue'

// Example: Create a simple Vue 3 app
// This will be used for new dashboard components
const app = createApp({
  data() {
    return {
      message: 'Vite + Vue 3 is ready for dashboard!'
    }
  }
})

// Mount Vue app only if target element exists
const viteApp = document.getElementById('vite-app')
if (viteApp) {
  app.mount('#vite-app')
}

// Export for global access if needed
window.ViteVue = { createApp }
