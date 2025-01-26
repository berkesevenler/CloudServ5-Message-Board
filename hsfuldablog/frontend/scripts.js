// Initialize API_BASE_URL properly
const API_BASE_URL = window.location.hostname === 'localhost'
    ? 'http://localhost:5001'  // Use localhost for development
    : 'http://backend:5001';   // Use backend service in Docker

window.onload = function () {
    if (window.location.pathname.includes('index.html')) {
        fetchPosts();
    }
};

async function fetchPosts() {
    try {
        const response = await fetch(`${API_BASE_URL}/posts`, {
            method: 'GET',
            headers: { 'Content-Type': 'application/json' }
        });
        const posts = await response.json();
        const postsList = document.getElementById('posts');
        postsList.innerHTML = '';

        if (posts.length === 0) {
            postsList.innerHTML = '<p>No posts available. Be the first to create one!</p>';
            return;
        }

        posts.forEach(post => {
            const postElement = document.createElement('div');
            postElement.className = 'post';
            postElement.innerHTML = `
                <div class="post-header">
                    <span class="post-author">${post.user}</span>
                    <span class="post-time">${formatTime(new Date(post.timestamp).getTime())}</span>
                </div>
                <div class="post-content">${post.content}</div>
            `;
            postsList.appendChild(postElement);
        });
    } catch (error) {
        console.error('Error fetching posts:', error);
        alert(`Failed to fetch posts: ${error.message || 'Unknown error'}`);
    }
}

async function createPost() {
    const content = document.getElementById('content').value;
    let username = document.getElementById('username').value.trim();

    // Generate a unique username if none is provided
    if (!username) {
        username = `anonymous${Date.now()}`; // Generate a unique username
    }

    if (!content.trim()) {
        alert('Please enter some content!');
        return;
    }

    const newPost = {
        user: username,
        content: content.trim()
    };

    try {
        const response = await fetch(`${API_BASE_URL}/posts`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(newPost)
        });

        if (response.ok) {
            await fetchPosts();
            document.getElementById('content').value = ''; // Clear content input after posting
            document.getElementById('username').value = ''; // Clear username input after posting
        } else {
            const errorData = await response.json();
            alert(`Failed to create post: ${errorData.error || 'Unknown error'}`);
        }
    } catch (error) {
        console.error('Error creating post:', error);
        alert(`Failed to create post: ${error.message || 'Unknown error'}`);
    }
}

function formatTime(timestamp) {
    const date = new Date(timestamp);
    return date.toLocaleString(undefined, { dateStyle: 'short', timeStyle: 'short' });
}

function logout() {
    localStorage.removeItem('username');
    window.location.href = "index.html";
}
