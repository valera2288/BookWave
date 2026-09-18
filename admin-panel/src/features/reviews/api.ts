import { apiClient } from "../../api/client";
import type { Paginated } from "../../shared/apiTypes";
import type { ReviewAdmin } from "./types";

export async function fetchReviews(page: number): Promise<Paginated<ReviewAdmin>> {
  const { data } = await apiClient.get<Paginated<ReviewAdmin>>("reviews/admin/", {
    params: { page },
  });
  return data;
}

export async function setReviewHidden(id: number, isHidden: boolean): Promise<ReviewAdmin> {
  const { data } = await apiClient.patch<ReviewAdmin>(`reviews/admin/${id}/`, {
    is_hidden: isHidden,
  });
  return data;
}

export async function deleteReview(id: number): Promise<void> {
  await apiClient.delete(`reviews/admin/${id}/`);
}
