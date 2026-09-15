export type Session = {
  id: number;
  name: string;
  email: string | null;
  role: string;
  currency?: string;
  access_token: string;
  refresh_token: string;
};

export type UserProfile = {
  id: number;
  name?: string;
  email?: string | null;
  phone?: string | null;
  profile_image?: string | null;
  currency?: string;
  total_farms?: number;
  total_followers?: number;
  total_posts?: number;
};

const apiBaseUrl = (process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://burning-yetty-bigboyme-428f3176.koyeb.app/api").replace(/\/+$/, "");

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers);
  if (!(init.body instanceof FormData)) headers.set("Content-Type", "application/json");
  const response = await fetch(`${apiBaseUrl}${path}`, {
    ...init,
    headers,
  });

  const body = (await response.json().catch(() => null)) as { detail?: string } | null;
  if (!response.ok) {
    throw new Error(body?.detail ?? "Une erreur est survenue.");
  }

  return body as T;
}

export function uploadImage(image: File, accessToken: string) {
  const form = new FormData();
  form.append("image", image);
  return request<{ url: string }>("/images/upload", {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}` },
    body: form,
  });
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

export type Livestock = {
  id: number;
  user_id?: number;
  animal_type: string;
  breed?: string;
  quantity?: number;
  age_months?: number;
  weight_kg?: number;
  health_status?: string;
  location?: string;
  notes?: string;
  image_url?: string;
  visibility?: string;
};

export function getMyLivestock(accessToken: string) {
  return request<Livestock[]>("/livestock/mine", {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
}

export function createLivestock(
  payload: Omit<Livestock, "id" | "user_id">,
  userId: number,
  accessToken: string,
) {
  return request<Livestock>(`/livestock/?user_id=${userId}`, {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}` },
    body: JSON.stringify(payload),
  });
}

export function updateLivestock(
  livestockId: number,
  payload: Omit<Livestock, "id" | "user_id">,
  accessToken: string,
) {
  return request<Livestock>(`/livestock/${livestockId}`, {
    method: "PUT",
    headers: { Authorization: `Bearer ${accessToken}` },
    body: JSON.stringify(payload),
  });
}

export function deleteLivestock(livestockId: number, accessToken: string) {
  return request<{ message: string }>(`/livestock/${livestockId}`, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${accessToken}` },
  });
}

export function createFarm(
  payload: { name: string; location?: string; size_hectares?: number; soil_type?: string; image_url?: string },
  userId: number,
  accessToken: string,
) {
  return request<FarmDetails>(`/farms/?user_id=${userId}`, {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}` },
    body: JSON.stringify(payload),
  });
}

export function updateFarm(
  farmId: number,
  payload: { name: string; location?: string; size_hectares?: number; soil_type?: string; image_url?: string },
  accessToken: string,
) {
  return request<FarmDetails>(`/farms/${farmId}`, {
    method: "PUT",
    headers: { Authorization: `Bearer ${accessToken}` },
    body: JSON.stringify(payload),
  });
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

export type CropDetails = {
  id: number;
  farm_id?: number;
  crop_name?: string;
  variety?: string;
  status?: string;
  area?: number;
  planted_date?: string;
  expected_harvest_date?: string;
  quantity_planted?: number;
  expected_yield?: number;
  notes?: string;
  image_url?: string;
  coordinates?: string | Array<Array<number>>;
};

export type FarmActivity = {
  id: number;
  crop_id?: number;
  activity_type?: string;
  activity_date?: string;
  notes?: string;
  input_id?: number;
  quantity_used?: number;
  finance_type?: string;
  finance_amount?: number;
  image_urls?: string[];
};

export type FarmInput = {
  id: number;
  crop_id?: number;
  input_type?: string;
  name?: string;
  quantity?: number;
  unit?: string;
  cost?: number;
  applied_date?: string;
  notes?: string;
};

export type FinanceTransaction = {
  id: number;
  crop_id?: number;
  transaction_type?: string;
  category?: string;
  amount?: number;
  transaction_date?: string;
  notes?: string;
};

export async function getFarmDetails(farmId: number, accessToken: string) {
  const headers = { Authorization: `Bearer ${accessToken}` };
  const [farm, crops, stats, finances, inputs, activities, transactions] = await Promise.all([
    request<FarmDetails>(`/farms/${farmId}`, { headers }),
    request<CropDetails[]>(`/farms/${farmId}/crops`, { headers }),
    request<FarmStats>(`/farms/${farmId}/stats`, { headers }),
    request<{ revenue_by_category?: Record<string, number>; top_products?: Array<{ product?: string; revenue?: number; quantity?: number }> }>(`/farms/${farmId}/financial-summary`, { headers }),
    request<FarmInput[]>(`/inputs/farm/${farmId}`, { headers }),
    request<FarmActivity[]>(`/activities/farm/${farmId}`, { headers }),
    request<FinanceTransaction[]>(`/finance/transactions/farm/${farmId}`, { headers }),
  ]);

  return { farm, crops, stats, finances, inputs, activities, transactions };
}

export async function createCrop(
  farmId: number,
  payload: { crop_name: string; status?: string; area?: number },
  accessToken: string,
) {
  return request(`/farms/${farmId}/crops`, {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}` },
    body: JSON.stringify(payload),
  });
}

export async function updateCrop(
  cropId: number,
  payload: { crop_name?: string; status?: string; area?: number },
  accessToken: string,
) {
  return request(`/crops/${cropId}`, {
    method: "PATCH",
    headers: { Authorization: `Bearer ${accessToken}` },
    body: JSON.stringify(payload),
  });
}

export async function deleteCrop(cropId: number, accessToken: string) {
  return request(`/crops/${cropId}`, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${accessToken}` },
  });
}

export function getCropActivities(cropId: number, accessToken: string) {
  return request<FarmActivity[]>(`/activities/crop/${cropId}`, { headers: { Authorization: `Bearer ${accessToken}` } });
}

export function getCropInputs(cropId: number, accessToken: string) {
  return request<FarmInput[]>(`/inputs/crop/${cropId}`, { headers: { Authorization: `Bearer ${accessToken}` } });
}

export function getCropTransactions(cropId: number, accessToken: string) {
  return request<FinanceTransaction[]>(`/finance/transactions/crop/${cropId}`, { headers: { Authorization: `Bearer ${accessToken}` } });
}

export function getCropProblems(cropId: number, accessToken: string) {
  return request<Array<Record<string, unknown>>>(`/crop-problems/crop/${cropId}`, { headers: { Authorization: `Bearer ${accessToken}` } });
}

export function getCropReminders(cropId: number, accessToken: string) {
  return request<Array<Record<string, unknown>>>(`/reminders/crop/${cropId}`, { headers: { Authorization: `Bearer ${accessToken}` } });
}

export function createActivity(payload: Record<string, unknown>, accessToken: string) {
  return request<FarmActivity>("/activities/", { method: "POST", headers: { Authorization: `Bearer ${accessToken}` }, body: JSON.stringify(payload) });
}

export function createInput(payload: Record<string, unknown>, accessToken: string) {
  return request<FarmInput>("/inputs/", { method: "POST", headers: { Authorization: `Bearer ${accessToken}` }, body: JSON.stringify(payload) });
}

export function createTransaction(payload: Record<string, unknown>, accessToken: string) {
  return request<FinanceTransaction>("/finance/transactions/", { method: "POST", headers: { Authorization: `Bearer ${accessToken}` }, body: JSON.stringify(payload) });
}

export function createSale(payload: Record<string, unknown>, accessToken: string) {
  return request<Record<string, unknown>>("/sales/", { method: "POST", headers: { Authorization: `Bearer ${accessToken}` }, body: JSON.stringify(payload) });
}

export function createReminder(payload: Record<string, unknown>, accessToken: string) {
  return request<Record<string, unknown>>("/reminders/", { method: "POST", headers: { Authorization: `Bearer ${accessToken}` }, body: JSON.stringify(payload) });
}

export function createProblem(payload: Record<string, unknown>, accessToken: string) {
  return request<Record<string, unknown>>("/crop-problems/", { method: "POST", headers: { Authorization: `Bearer ${accessToken}` }, body: JSON.stringify(payload) });
}

export type NetworkPost = {
  id: number;
  farm_id?: number;
  farm_name?: string;
  owner_name?: string;
  owner_profile_image?: string;
  image_url?: string;
  caption?: string;
  likes_count?: number;
  comments_count?: number;
  shares_count?: number;
  created_at?: string;
  is_liked?: boolean;
  post_intent?: string;
  price?: number;
  unit?: string;
};

export type MarketSale = {
  id: number;
  product_name?: string;
  quantity?: number;
  unit?: string;
  price_per_unit?: number;
  currency?: string;
  category?: string;
  delivery_location?: string;
  description?: string;
  image_url?: string;
  user_id?: number;
};

export type MarketPrice = {
  id: number;
  product_name?: string;
  region?: string;
  price_per_kg?: number;
  currency?: string;
  price_date?: string;
  source?: string;
};

export function getNetworkFeed(userId: number, accessToken: string) {
  return request<NetworkPost[]>(`/farm-posts/feed?user_id=${userId}`, { headers: { Authorization: `Bearer ${accessToken}` } });
}

export function likeNetworkPost(postId: number, accessToken: string) {
  return request(`/farm-posts/${postId}/like`, { method: "POST", headers: { Authorization: `Bearer ${accessToken}` } });
}

export function unlikeNetworkPost(postId: number, accessToken: string) {
  return request(`/farm-posts/${postId}/like`, { method: "DELETE", headers: { Authorization: `Bearer ${accessToken}` } });
}

export function getNetworkPostComments(postId: number, accessToken: string) {
  return request<Array<Record<string, unknown>>>(`/farm-posts/${postId}/comments`, { headers: { Authorization: `Bearer ${accessToken}` } });
}

export function addNetworkPostComment(postId: number, userId: number, commentText: string, accessToken: string) {
  return request<Record<string, unknown>>(`/farm-posts/${postId}/comments`, { method: "POST", headers: { Authorization: `Bearer ${accessToken}` }, body: JSON.stringify({ user_id: userId, comment_text: commentText }) });
}

export async function getMarketSales(accessToken: string) {
  const response = await request<MarketSale[] | { items?: MarketSale[] }>("/sales/?page=1&limit=100", { headers: { Authorization: `Bearer ${accessToken}` } });
  return Array.isArray(response) ? response : response.items ?? [];
}

export function getMarketPrices(accessToken: string) {
  return request<MarketPrice[]>("/market/prices", { headers: { Authorization: `Bearer ${accessToken}` } });
}

export function getUserProfile(userId: number, accessToken: string, viewerId?: number) {
  const query = viewerId ? `?viewer_id=${viewerId}` : "";
  return request<UserProfile>(`/users/${userId}/profile${query}`, { headers: { Authorization: `Bearer ${accessToken}` } });
}

export { apiBaseUrl };