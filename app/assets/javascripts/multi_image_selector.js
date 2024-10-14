// customize but still call original
// (function() {
//     console.log('Checking multiImageSelector before any modifications:', $.fn.multiImageSelector);
  
//     // Check if the upstream multiImageSelector function exists
//     if (typeof $.fn.multiImageSelector === 'function') {
//       // Store the upstream function if it hasn't been stored already
//       if (!$.fn.multiImageSelector.original) {
//         $.fn.multiImageSelector.original = $.fn.multiImageSelector;
//         console.log('Original multiImageSelector function stored successfully.');
//       }
  
//       // Override the upstream function
//       const originalFunction = $.fn.multiImageSelector.original;
//       $.fn.multiImageSelector = function(image_versions, clickCallback, activeImageId) {
//         console.log('Custom multiImageSelector called!', { image_versions, activeImageId });
  
//         // Check if the original function is defined
//         if (typeof originalFunction === 'function') {
//           return originalFunction.apply(this, [image_versions, function(){console.log("custom")}, activeImageId]);
//         } else {
//           console.error('Original multiImageSelector function is not available.');
//         }
//       };
//     } else {
//       console.error('multiImageSelector function does not exist yet.');
//     }
//   })();
  
// never call original
(function() {
    console.log('Overriding multiImageSelector with custom implementation');
  
    // Check if the upstream multiImageSelector function exists
    if (typeof $.fn.multiImageSelector === 'function') {
      // Override the upstream function completely
      $.fn.multiImageSelector = function(image_versions, clickCallback, activeImageId) {
        console.log('Custom multiImageSelector called!', { image_versions, activeImageId });
  
        // Your custom logic here
        // Example: Just log the images
        image_versions.forEach(version => {
          console.log('Image ID:', version.imageId, 'Thumbnail:', version.thumb);
        });
  
        // Implement your custom behavior instead of calling the original
  
        // Return whatever you need; can be undefined if not necessary
        return this;
      };
    } else {
      console.error('multiImageSelector function does not exist yet.');
    }
  })();
  