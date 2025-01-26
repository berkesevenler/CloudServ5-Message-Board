window.onload = function () {
    if (window.location.pathname.includes('blog.html')) {
        const username = getUsername();
        if (username) {
            document.getElementById('user-display').textContent = `Logged in as: ${username}`;
        } else {
            alert('No username found. Redirecting to welcome page.');
            window.location.href = "index.html";
        }
        fetchPosts();
    }
};

function getUsername() {
    return localStorage.getItem('username') || '';
}

async function fetchPosts() {
    try {
        const response = await fetch('http://backend:5000/posts');
        const posts = await response.json();
        const postsList = document.getElementById('posts');
        postsList.innerHTML = '';

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
        alert('Failed to load posts. Please try again later.');
    }
}

async function createPost() {
    const content = document.getElementById('content').value;
    const username = localStorage.getItem('username');

    if (!content.trim()) {
        alert('Please enter some content!');
        return;
    }

    const newPost = {
        user: username,
        content: content.trim()
    };

    try {
        const response = await fetch('http://backend:5000/posts', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(newPost)
        });

        if (response.ok) {
            fetchPosts();
            document.getElementById('content').value = '';
        } else {
            alert('Failed to create post. Please try again.');
        }
    } catch (error) {
        console.error('Error creating post:', error);
        alert('Failed to create post. Please try again.');
    }
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
    window.location.href = "index.html";
}
