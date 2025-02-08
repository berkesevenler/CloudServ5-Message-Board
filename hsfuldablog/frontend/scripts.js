// Initialize API_BASE_URL properly
const API_BASE_URL = 'http://REPLACE_LB_FIP:5001';

window.onload = function () {
    // Fetch posts when the website loads
    fetchPosts();
};

async function fetchPosts() {
    try {
        const response = await fetch(`${API_BASE_URL}/posts`, {
            method: 'GET',
            headers: { 'Content-Type': 'application/json' }
        });

        if (!response.ok) {
            throw new Error('Failed to fetch posts');
        }

        const posts = await response.json();
        const postsList = document.getElementById('posts');
        postsList.innerHTML = '';

        if (posts.length === 0) {
            postsList.innerHTML = '<p>No posts available. Be the first to create one!</p>';
            return;
        }

        // Reverse the posts array to display newest posts first
        posts.reverse();

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
        const postsList = document.getElementById('posts');
        postsList.innerHTML = `<p>Failed to fetch posts: ${error.message || 'Unknown error'}</p>`;
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
            await fetchPosts(); // Refresh posts after creating a new one
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
