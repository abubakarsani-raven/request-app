#!/usr/bin/env node

/**
 * Script to update all API route files to use centralized server-config
 * instead of hardcoded API_BASE/API_BASE_URL constants
 */

const fs = require('fs');
const path = require('path');

const API_ROUTES_DIR = path.join(__dirname, '../app/api');

// Patterns to match
const API_BASE_PATTERNS = [
  /const\s+API_BASE\s*=\s*process\.env\.NEXT_PUBLIC_API_BASE_URL\s*\|\|\s*['"]http:\/\/localhost:4000['"];?/,
  /const\s+API_BASE_URL\s*=\s*process\.env\.NEXT_PUBLIC_API_BASE_URL\s*\|\|\s*['"]http:\/\/localhost:4000['"];?/,
];

// Recursively find all route.ts files
function findRouteFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir);
  files.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      findRouteFiles(filePath, fileList);
    } else if (file === 'route.ts') {
      fileList.push(filePath);
    }
  });
  return fileList;
}

async function updateApiRoutes() {
  console.log('🔍 Finding all API route files...');
  
  // Find all route.ts files
  const routeFiles = findRouteFiles(API_ROUTES_DIR);

  console.log(`📁 Found ${routeFiles.length} route files\n`);

  let updatedCount = 0;
  let skippedCount = 0;

  for (const filePath of routeFiles) {
    try {
      let content = fs.readFileSync(filePath, 'utf8');
      const originalContent = content;
      
      // Skip if already using server-config
      if (content.includes('@/lib/server-config') || content.includes("from '@/lib/server-config'")) {
        console.log(`⏭️  Skipping ${path.relative(API_ROUTES_DIR, filePath)} (already updated)`);
        skippedCount++;
        continue;
      }

      // Check if file has the pattern we need to replace
      const hasApiBase = API_BASE_PATTERNS.some(pattern => pattern.test(content));
      if (!hasApiBase) {
        // Also check for files that don't have the pattern but might need updating
        const hasLocalhostFallback = /process\.env\.NEXT_PUBLIC_API_BASE_URL\s*\|\|\s*['"]http:\/\/localhost:4000['"]/.test(content);
        if (!hasLocalhostFallback) {
          console.log(`⏭️  Skipping ${path.relative(API_ROUTES_DIR, filePath)} (no API_BASE found)`);
          skippedCount++;
          continue;
        }
      }

      // Determine which variable name is used (API_BASE or API_BASE_URL)
      const usesApiBase = /const\s+API_BASE\s*=/.test(content);
      const variableName = usesApiBase ? 'API_BASE' : 'API_BASE_URL';

      // Remove the const declaration line
      content = content.replace(
        /const\s+(API_BASE|API_BASE_URL)\s*=\s*process\.env\.NEXT_PUBLIC_API_BASE_URL\s*\|\|\s*['"]http:\/\/localhost:4000['"];?\n?/g,
        ''
      );

      // Add import statement after existing imports
      const importMatch = content.match(/^import\s+.*?from\s+['"].*?['"];?\n/m);
      if (importMatch) {
        // Find the last import statement
        const importLines = content.match(/^import\s+.*?from\s+['"].*?['"];?\n/gm) || [];
        const lastImportIndex = content.lastIndexOf(importLines[importLines.length - 1]);
        const insertIndex = lastImportIndex + importLines[importLines.length - 1].length;
        
        // Insert the new import
        content = content.slice(0, insertIndex) + 
                  `import { API_BASE_URL } from '@/lib/server-config';\n` + 
                  content.slice(insertIndex);
      } else {
        // No imports found, add at the top
        content = `import { API_BASE_URL } from '@/lib/server-config';\n\n` + content;
      }

      // Replace all usages of the old variable name with API_BASE_URL
      if (variableName === 'API_BASE') {
        // Replace API_BASE with API_BASE_URL, but be careful not to replace in strings or comments
        content = content.replace(/\bAPI_BASE\b/g, 'API_BASE_URL');
      }

      // Write the updated content
      if (content !== originalContent) {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`✅ Updated ${path.relative(API_ROUTES_DIR, filePath)}`);
        updatedCount++;
      } else {
        console.log(`⚠️  No changes made to ${path.relative(API_ROUTES_DIR, filePath)}`);
      }
    } catch (error) {
      console.error(`❌ Error processing ${path.relative(API_ROUTES_DIR, filePath)}:`, error.message);
    }
  }

  console.log(`\n✨ Done! Updated ${updatedCount} files, skipped ${skippedCount} files`);
}

// Run the script
updateApiRoutes().catch(console.error);
