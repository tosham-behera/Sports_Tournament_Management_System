document.addEventListener('DOMContentLoaded', () => {
    const themeToggle = document.getElementById('theme-toggle');
    const body = document.documentElement;
    
    const set_theme = (theme) => {
        if (theme === 'dark') {
            body.setAttribute('data-theme', 'dark');
            themeToggle.innerHTML = '<span>☀️</span>';
            localStorage.setItem('theme', 'dark');
        } else {
            body.removeAttribute('data-theme');
            themeToggle.innerHTML = '<span>🌙</span>';
            localStorage.setItem('theme', 'light');
        }
    };

    const currentTheme = localStorage.getItem('theme');
    if (currentTheme === 'dark' || (!currentTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
        set_theme('dark');
    } else {
        set_theme('light');
    }

    themeToggle.addEventListener('click', () => {
        const isDark = body.getAttribute('data-theme') === 'dark';
        set_theme(isDark ? 'light' : 'dark');
    });

    const shieldToggle = document.getElementById('shield-toggle');
    const eyeShield = document.getElementById('eye-shield');

    const set_shield = (active) => {
        if (active) {
            eyeShield.classList.add('active');
            shieldToggle.classList.add('active-shield');
            localStorage.setItem('shield', 'active');
        } else {
            eyeShield.classList.remove('active');
            shieldToggle.classList.remove('active-shield');
            localStorage.setItem('shield', 'inactive');
        }
    };

    const shieldActive = localStorage.getItem('shield') === 'active';
    set_shield(shieldActive);

    shieldToggle.addEventListener('click', () => {
        const isActive = eyeShield.classList.contains('active');
        set_shield(!isActive);
    });

    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-in');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    document.querySelectorAll('.card, .sport-card, section').forEach(el => {
        el.classList.add('reveal');
        observer.observe(el);
    });

    const sections = document.querySelectorAll('section[id]');
    window.addEventListener('scroll', () => {
        let current = '';
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;
            if (pageYOffset >= sectionTop - 150) {
                current = section.getAttribute('id');
            }
        });

        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href').substring(1) === current) {
                link.classList.add('active');
            }
        });
    });

    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', (e) => {
            const submitBtn = form.querySelector('button[type="submit"]');
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<span class="spinner"></span> Processing...';
            }
        });
    });

    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            alert.style.opacity = '0';
            alert.style.transform = 'translateY(-10px)';
            setTimeout(() => alert.remove(), 500);
        }, 5000);
    });
});
