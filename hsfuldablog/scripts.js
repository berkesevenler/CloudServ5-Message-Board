window.onload = function () {
    if (window.location.pathname.includes('blog.html')) {
        const username = getUsername();
        if (username) {
            document.getElementById('user-display').textContent = `Logged in as: ${username}`;
        } else {
            alert('No username found. Redirecting to welcome page.');
            window.location.href = "greeting.html";
        }
        fetchPosts(); 
    }
};

function getUsername() {
    return localStorage.getItem('username') || '';
}

function getPosts() {
    const posts = JSON.parse(localStorage.getItem('posts')) || [];
    return posts.filter(post => !isExpired(post));
}

function savePosts(posts) {
    localStorage.setItem('posts', JSON.stringify(posts));
}

function isExpired(post) {
    const now = Date.now();
    return now - post.timestamp > 24 * 60 * 60 * 1000; 
}

function fetchPosts() {
    const posts = getPosts();
    const postsList = document.getElementById('posts');
    const currentUser = getUsername();
    postsList.innerHTML = '';

    posts.forEach(post => {
        const postElement = document.createElement('div');
        postElement.className = 'post';
        postElement.innerHTML = `
            <div class="post-header">
                <span class="post-author">${post.user}</span>
                <span class="post-time">${formatTime(post.timestamp)}</span>
            </div>
            ${post.content ? `<div class="post-content">${post.content}</div>` : ''}
            ${post.file ? getFileDisplay(post.file, post.fileType) : ''}
            <div class="post-actions">
                <button onclick="likePost(${post.id})" 
                    class="like-btn ${post.likedBy.includes(currentUser) ? 'active' : ''}">
                    ${post.likes}
                </button>
                <button onclick="dislikePost(${post.id})" 
                    class="dislike-btn ${post.dislikedBy.includes(currentUser) ? 'active' : ''}">
                    ${post.dislikes}
                </button>
                ${post.user === currentUser ? 
                    `<button onclick="deletePost(${post.id})" class="delete-btn">Delete</button>` : 
                    ''
                }
            </div>
        `;
        postsList.appendChild(postElement);
    });

    savePosts(posts);
}

function createPost() {
    const content = document.getElementById('content').value;
    const fileInput = document.getElementById('file-upload');
    const username = localStorage.getItem('username');
    
    if (!content.trim() && (!fileInput.files || !fileInput.files[0])) {
        alert('Please add either a message or a file to post!');
        return;
    }

    const newPost = {
        id: Date.now(),
        user: username,
        content: content.trim(),
        timestamp: Date.now(),
        likes: 0,
        dislikes: 0,
        likedBy: [],
        dislikedBy: [],
        file: null,
        fileType: null
    };

    if (fileInput.files && fileInput.files[0]) {
        const file = fileInput.files[0];
        const reader = new FileReader();
        reader.onload = function(e) {
            newPost.file = e.target.result;
            newPost.fileType = file.type;
            saveAndRefresh(newPost);
        }
        reader.readAsDataURL(file);
    } else {
        saveAndRefresh(newPost);
    }
}

function saveAndRefresh(newPost) {
    const posts = getPosts() || [];
    posts.unshift(newPost);
    localStorage.setItem('posts', JSON.stringify(posts));
    fetchPosts();
    
    document.getElementById('content').value = '';
    
    document.getElementById('file-upload').value = '';
    document.getElementById('file-preview').innerHTML = '';
}

function deletePost(id) {
    const posts = getPosts();
    const updatedPosts = posts.filter(post => post.id !== id);
    savePosts(updatedPosts);
    fetchPosts();
}

function likePost(id) {
    const username = getUsername();
    if (!username) return;

    const posts = getPosts();
    const post = posts.find(post => post.id === id);

    if (post) {
        if (post.likedBy.includes(username)) {
            post.likedBy = post.likedBy.filter(user => user !== username);
            post.likes -= 1;
        } 
        else if (post.dislikedBy.includes(username)) {
            post.dislikedBy = post.dislikedBy.filter(user => user !== username);
            post.dislikes -= 1;
            post.likedBy.push(username);
            post.likes += 1;
        }
        else {
            post.likedBy.push(username);
            post.likes += 1;
        }
    }

    savePosts(posts);
    fetchPosts();
}

function dislikePost(id) {
    const username = getUsername();
    if (!username) return;

    const posts = getPosts();
    const post = posts.find(post => post.id === id);

    if (post) {
        if (post.dislikedBy.includes(username)) {
            post.dislikedBy = post.dislikedBy.filter(user => user !== username);
            post.dislikes -= 1;
        }
        else if (post.likedBy.includes(username)) {
            post.likedBy = post.likedBy.filter(user => user !== username);
            post.likes -= 1;
            post.dislikedBy.push(username);
            post.dislikes += 1;
        }
        else {
            post.dislikedBy.push(username);
            post.dislikes += 1;
        }
    }

    savePosts(posts);
    fetchPosts();
}

function formatTime(timestamp) {
    const now = Date.now();
    const diff = now - timestamp;

    const hours = Math.floor(diff / (60 * 60 * 1000));
    if (hours > 0) {
        return `${hours} hour${hours > 1 ? 's' : ''} ago`;
    }

    const minutes = Math.floor(diff / (60 * 1000));
    return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
}

function logout() {
    localStorage.removeItem('username');
    window.location.href = "greeting.html";
}

function handleFileSelect() {
    const fileInput = document.getElementById('file-upload');
    const preview = document.getElementById('file-preview');
    
    const file = fileInput.files[0];
    if (!file) {
        preview.innerHTML = '';
        return;
    }
    
    preview.innerHTML = `
        <div class="file-preview-item">
            <span class="file-name">${file.name}</span>
            <button onclick="removeFile()" class="remove-file-btn">✕</button>
        </div>
        ${getFilePreview(file)}
    `;
}

function removeFile() {
    const fileInput = document.getElementById('file-upload');
    const preview = document.getElementById('file-preview');
    fileInput.value = '';
    preview.innerHTML = '';
}

function getFilePreview(file) {
    if (file.type.startsWith('image/')) {
        return `<img src="${URL.createObjectURL(file)}" class="file-preview-image">`;
    } else if (file.type.startsWith('video/')) {
        return `<video controls class="file-preview-video">
                    <source src="${URL.createObjectURL(file)}" type="${file.type}">
                </video>`;
    } else {
        return `<div class="file-type-icon">
            <span class="file-type">${file.type.split('/')[0].toUpperCase()}</span>
        </div>`;
    }
}

function getFileDisplay(file, fileType) {
    if (fileType.startsWith('image/')) {
        return `<div class="post-file-container">
            <img src="${file}" alt="Post image" class="post-image">
        </div>`;
    } else if (fileType.startsWith('video/')) {
        return `<div class="post-file-container">
            <video controls class="post-video">
                <source src="${file}" type="${fileType}">
            </video>
        </div>`;
    } else {
        return `<div class="post-file-container">
            <a href="${file}" download class="file-download">
                Download ${fileType.split('/')[0].toUpperCase()} File
            </a>
        </div>`;
    }
}


