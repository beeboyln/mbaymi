import type { FormEvent } from "react";
import { Heart, MessageCircle, RefreshCw, Sprout, Users, X } from "lucide-react";

type Post = Record<string, unknown>;

type NetworkViewProps = {
  posts: Post[];
  loading: boolean;
  actionNotice: string;
  commentsPost: Post | null;
  comments: Post[];
  commentsLoading: boolean;
  commentText: string;
  formatDate: (value?: string) => string;
  onRefresh: () => void;
  onLike: (post: Post) => void;
  onOpenComments: (post: Post) => void;
  onCloseComments: () => void;
  onCommentTextChange: (value: string) => void;
  onSubmitComment: (event: FormEvent<HTMLFormElement>) => void;
};

export default function NetworkView({
  posts, loading, actionNotice, commentsPost, comments, commentsLoading, commentText,
  formatDate, onRefresh, onLike, onOpenComments, onCloseComments, onCommentTextChange, onSubmitComment,
}: Readonly<NetworkViewProps>) {
  return <div className="social-view">
    <div className="section-page-heading"><div><p className="eyebrow">RÉSEAU AGRICOLE</p><h2>Les nouvelles du terrain</h2><p>Découvrez les publications des fermes et des agriculteurs suivis.</p></div><button className="outline-action" onClick={onRefresh}><RefreshCw size={15} aria-hidden="true" /> Actualiser</button></div>
    {actionNotice && <p className="action-notice" role="alert">{actionNotice}</p>}
    {loading ? <div className="farm-detail-loading">Chargement du réseau...</div> : posts.length ? <div className="social-feed">{posts.map((post) => <article className="social-post" key={String(post.id)}>{Boolean(post.image_url) && <img src={String(post.image_url)} alt="" />}<div className="social-post-body"><div className="social-post-meta"><span><Sprout size={15} aria-hidden="true" /> {String(post.farm_name || "Ferme")}</span><small>{formatDate(String(post.created_at || ""))}</small></div><h3>{String(post.owner_name || "Agriculteur")}</h3><p>{String(post.caption || "Une nouvelle publication agricole.")}</p><div className="social-post-actions"><button onClick={() => onLike(post)}><Heart size={16} fill={post.is_liked ? "currentColor" : "none"} aria-hidden="true" /> {String(post.likes_count || 0)}</button><button onClick={() => onOpenComments(post)}><MessageCircle size={16} aria-hidden="true" /> {String(post.comments_count || 0)}</button></div></div></article>)}</div> : <div className="farms-empty-state"><Users size={38} aria-hidden="true" /><h3>Le réseau se construit ici.</h3><p>Les publications des fermes apparaîtront dès qu&apos;elles seront partagées.</p></div>}
    {commentsPost && <div className="comments-modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) onCloseComments(); }}><section className="comments-modal"><header><div><span className="metric-label">DISCUSSION</span><h3>{String(commentsPost.farm_name || "Publication")}</h3></div><button onClick={onCloseComments} aria-label="Fermer"><X size={20} /></button></header><div className="comments-list">{commentsLoading ? <p>Chargement...</p> : comments.length ? comments.map((comment) => <div className="comment-item" key={String(comment.id)}><strong>{String(comment.user_name || "Utilisateur")}</strong><p>{String(comment.comment || "")}</p></div>) : <p className="detail-empty">Aucun commentaire. Soyez le premier à répondre.</p>}</div><form onSubmit={onSubmitComment}><input value={commentText} onChange={(event) => onCommentTextChange(event.target.value)} placeholder="Écrire un commentaire..." /><button type="submit"><MessageCircle size={17} /></button></form></section></div>}
  </div>;
}
