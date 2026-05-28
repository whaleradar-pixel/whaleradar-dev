import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { SubscriptionPlan, SubscriptionPlanId, canAccessPlan } from '../types';
import { useAuth } from '../contexts/AuthContext';

export function useSubscription() {
  const { profile } = useAuth();
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase
      .from('subscription_plans')
      .select('*')
      .order('sort_order')
      .then(({ data }) => {
        if (data) {
          setPlans(data.map((p) => ({ ...p, features: p.features as string[] })));
        }
        setLoading(false);
      });
  }, []);

  const currentPlan = profile?.subscription_plan ?? 'free';
  const isExpired = profile?.subscription_expires_at
    ? new Date(profile.subscription_expires_at) < new Date()
    : false;
  const effectivePlan: SubscriptionPlanId = isExpired ? 'free' : currentPlan;

  const hasAccess = (requiredPlan: SubscriptionPlanId) =>
    canAccessPlan(effectivePlan, requiredPlan);

  return { plans, loading, currentPlan: effectivePlan, hasAccess, isExpired };
}
