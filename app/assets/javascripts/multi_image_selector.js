// never call original
(function() {
    console.log('Overriding multiImageSelector with custom implementation');
    // Check if the upstream multiImageSelector function exists
    if (typeof $.fn.multiImageSelector === 'function') {
      // Override the upstream function completely
      $.fn.multiImageSelector = function(image_versions, clickCallback, activeImageId) {
        console.log('Custom multiImageSelector called!', { image_versions, activeImageId });

        // TODO: use init function like in Spotlight
  
        // Placeholder: Just log the images
        // image_versions.forEach(version => {
          // console.log('Image ID:', version.imageId, 'Thumbnail:', version.thumb);
        // });
  
        // Implement custom behavior...
        // TODO: open modal / mirador viewer

        el = this;

        const modalHTML = `
          <div class="modal fade" id="imageModal" tabindex="-1" role="dialog" aria-labelledby="imageModalLabel" aria-hidden="true">
              <div class="modal-dialog" role="document">
                  <div class="modal-content">
                      <div class="modal-header">
                          <h5 class="modal-title" id="imageModalLabel">Image Selector</h5>
                          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                              <span aria-hidden="true">&times;</span>
                          </button>
                      </div>
                      <div class="modal-body">
                          <p>Images will be displayed here.</p>
                      </div>
                      <div class="modal-footer">
                          <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                      </div>
                  </div>
              </div>
          </div>
        `;
 
        // Append the modal HTML
        $(el).find('.card-header .main').append(modalHTML);

        // Modal link to ViewComponent Thank You
        const link = $('<a class="nav-link" data-blacklight-modal="trigger" href="/edit_image_area">Edit image area</a>');
        // const link = $('<a href="#" class="">Open Image Selector</a>');
        // link.on('click', function(e) {
        //   e.preventDefault(); // Prevent the default anchor behavior
        //   $('#imageModal').modal('show'); // Show the modal
        // });

        $(el).find('.card-header .main').append(link);

  
        // Return whatever is needed...
        return el;
      };
    } else {
      console.error('multiImageSelector function does not exist yet.');
    }
  })();
  