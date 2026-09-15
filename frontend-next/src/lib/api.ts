export type Session = {
  id: number;
  name: string;
  email: string | null;
  role: string;
  currency?: string;
  access_token: string;
  refresh_token: string;
};

const apiBaseUrl = (process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://burning-yetty-bigboyme-428f3176.koyeb.app/api").replace(/\/+$/, "");

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const response = await fetch(`${apiBaseUrl}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...init.headers,
    },
  });

  const body = (await response.json().catch(() => null)) as { detail?: string } | null;
  if (!response.ok) {
    throw new Error(body?.detail ?? "Une erreur est survenue.");
  }

  return body as T;
}

export function login(identifier: string, password: string) {
  return request<Session>("/auth/login", {
    method: "POST",
    body: JSON.stringify({ email: identifier, password }),
  });
}

export async function getFarms(accessToken: string) {
  return request<Array<{ id: number; name: string; location?: string; size_hectares?: number; image_url?: string; photos?: Array<{ id: number; image_url?: string }>; crops?: Array<{ crop_name?: string }>; livestocks?: Array<unknown> }>>(
    "/farms/",
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );
}

export type FarmDetails = {
  id: number;
  name: string;
  location?: string;
  size_hectares?: number;
  soil_type?: string;
  image_url?: string;
  photos?: Array<{ id: number; image_url?: string }>;
};

export type FarmStats = {
  parcel_count?: number;
  livestock_count?: number;
  total_revenue?: number;
  total_expenses?: number;
  net_income?: number;
  average_parcel_size?: number;
};

export async function getFarmDetails(farmId: number, accessToken: string) {
  const headers = { Authorization: `Bearer ${accessToken}` };
  const [farm, crops, stats, finances] = await Promise.all([
    request<FarmDetails>(`/farms/${farmId}`, { headers }),
    request<Array<{ id: number; crop_name?: string; status?: string; area?: number; expected_yield?: number }>>(`/farms/${farmId}/crops`, { headers }),
    request<FarmStats>(`/farms/${farmId}/stats`, { headers }),
    request<{ revenue_by_category?: Record<string, number>; top_products?: Array<{ product?: string; revenue?: number; quantity?: number }> }>(`/farms/${farmId}/financial-summary`, { headers }),
  ]);

  return { farm, crops, stats, finances };
}

export { apiBaseUrl };