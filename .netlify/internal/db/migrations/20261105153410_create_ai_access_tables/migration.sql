CREATE TABLE "access_links" (
	"id" serial PRIMARY KEY,
	"token" text NOT NULL UNIQUE,
	"tier" text NOT NULL,
	"customer_name" text DEFAULT '' NOT NULL,
	"customer_email" text DEFAULT '' NOT NULL,
	"note" text DEFAULT '' NOT NULL,
	"message_limit" integer NOT NULL,
	"messages_used" integer DEFAULT 0 NOT NULL,
	"expires_at" timestamp with time zone,
	"revoked" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"last_used_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "conversations" (
	"id" serial PRIMARY KEY,
	"link_id" integer NOT NULL,
	"title" text DEFAULT 'New chat' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "jobs" (
	"id" text PRIMARY KEY,
	"link_id" integer NOT NULL,
	"conversation_id" integer NOT NULL,
	"status" text DEFAULT 'queued' NOT NULL,
	"step" integer DEFAULT 0 NOT NULL,
	"total_steps" integer DEFAULT 1 NOT NULL,
	"step_label" text DEFAULT 'Waiting' NOT NULL,
	"partial" text DEFAULT '' NOT NULL,
	"error" text DEFAULT '' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "messages" (
	"id" serial PRIMARY KEY,
	"conversation_id" integer NOT NULL,
	"role" text NOT NULL,
	"content" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "settings" (
	"key" text PRIMARY KEY,
	"value" text NOT NULL
);
--> statement-breakpoint
CREATE INDEX "conversations_link_idx" ON "conversations" ("link_id");--> statement-breakpoint
CREATE INDEX "jobs_conversation_idx" ON "jobs" ("conversation_id");--> statement-breakpoint
CREATE INDEX "messages_conversation_idx" ON "messages" ("conversation_id");--> statement-breakpoint
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_link_id_access_links_id_fkey" FOREIGN KEY ("link_id") REFERENCES "access_links"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "jobs" ADD CONSTRAINT "jobs_link_id_access_links_id_fkey" FOREIGN KEY ("link_id") REFERENCES "access_links"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "jobs" ADD CONSTRAINT "jobs_conversation_id_conversations_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "messages" ADD CONSTRAINT "messages_conversation_id_conversations_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE;