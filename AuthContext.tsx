import { useState } from 'react';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import Subscription from './pages/Subscription';
import Profile from './pages/Profile';
import Admin from './pages/Admin';
import AdminLogin from './pages/AdminLogin';
import Landing from './pages/Landing';
import WhaleActivity from './pages/WhaleActivity';
import Sidebar from './components/Sidebar';
import AccessibilityWidget from './components/AccessibilityWidget';

type AuthScreen = 'login' | 'register';
type AppPage = 'dashboard' | 'subscription' | 'profile' | 'whales';
type RootView = 'landing' | 'app';

function AppInner() {
  const { user, loading } = useAuth();
  const [rootView, setRootView] = useState<RootView>('landing');
  const [authScreen, setAuthScreen] = useState<AuthScreen>('login');
  const [page, setPage] = useState<AppPage>('dashboard');
  const [adminAuthed, setAdminAuthed] = useState(
    () => sessionStorage.getItem('wr_admin_auth') === 'true'
  );

  const isAdminRoute = window.location.hash === '#admin';
  const isImpersonateRoute = window.location.hash === '#app-impersonate';

  if (loading) {
    return (
      <div className="min-h-screen bg-[#0b0f1a] flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-2 border-cyan-500/30 border-t-cyan-500 rounded-full animate-spin mx-auto mb-4" />
          <p className="text-slate-500 text-sm">טוען...</p>
        </div>
      </div>
    );
  }

  if (isImpersonateRoute) {
    const raw = sessionStorage.getItem('wr_impersonation');
    const imp = raw ? JSON.parse(raw) : null;
    if (imp && Date.now() - imp.timestamp < 30 * 60 * 1000) {
      return (
        <>
          <div className="fixed top-0 left-0 right-0 z-50 bg-amber-500/90 text-black text-center py-2 text-sm font-bold">
            מצב צפייה: {imp.fullName} ({imp.email}) — אדמין בלבד
          </div>
          <div className="pt-10 flex h-screen bg-[#0b0f1a] overflow-hidden" dir="rtl">
            <Sidebar currentPage={page} onNavigate={setPage} />
            <main className="flex-1 overflow-hidden flex flex-col md:pt-0 pb-[57px] md:pb-0">
              {page === 'dashboard' && <Dashboard onNavigateSubscription={() => setPage('subscription')} />}
              {page === 'subscription' && <Subscription />}
              {page === 'profile' && <Profile />}
            </main>
          </div>
        </>
      );
    }
  }

  if (isAdminRoute) {
    if (!adminAuthed) {
      return (
        <>
          <AdminLogin onAuthenticated={() => setAdminAuthed(true)} />
          <AccessibilityWidget />
        </>
      );
    }
    return (
      <>
        <Admin />
        <AccessibilityWidget />
      </>
    );
  }

  if (!user && rootView === 'landing') {
    return (
      <>
        <Landing onEnterApp={() => setRootView('app')} />
        <AccessibilityWidget />
      </>
    );
  }

  if (!user) {
    if (authScreen === 'register') {
      return <Register onSwitch={() => setAuthScreen('login')} onSuccess={() => setAuthScreen('login')} />;
    }
    return <Login onSwitch={() => setAuthScreen('register')} />;
  }

  // Main app
  return (
    <>
      <div className="flex h-screen bg-[#0b0f1a] overflow-hidden" dir="rtl">
        <Sidebar currentPage={page} onNavigate={setPage} />
        <main className="flex-1 overflow-hidden flex flex-col md:pt-0 pt-[57px] pb-[57px] md:pb-0">
          {page === 'dashboard' && <Dashboard onNavigateSubscription={() => setPage('subscription')} />}
          {page === 'whales' && <WhaleActivity onNavigateSubscription={() => setPage('subscription')} />}
          {page === 'subscription' && <Subscription />}
          {page === 'profile' && <Profile />}
        </main>
      </div>
      <AccessibilityWidget />
    </>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <AppInner />
    </AuthProvider>
  );
}
