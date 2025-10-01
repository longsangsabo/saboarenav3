-- Notification Analytics SQL Functions và Tables
-- Tạo tables và functions để support notification analytics

-- Create analytics events table
CREATE TABLE IF NOT EXISTS notification_analytics_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_id VARCHAR(255),
    event_data JSONB,
    session_id VARCHAR(255),
    device_info JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_analytics_events_user_id ON notification_analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_notification_id ON notification_analytics_events(notification_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_name ON notification_analytics_events(event_name);
CREATE INDEX IF NOT EXISTS idx_analytics_events_created_at ON notification_analytics_events(created_at);
CREATE INDEX IF NOT EXISTS idx_analytics_events_composite ON notification_analytics_events(user_id, event_name, created_at);

-- Enable RLS
ALTER TABLE notification_analytics_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own analytics events" ON notification_analytics_events
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all analytics events" ON notification_analytics_events
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Function: Get user notification stats
CREATE OR REPLACE FUNCTION get_user_notification_stats(user_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    total_notifications INT;
    unread_count INT;
    read_count INT;
    read_rate FLOAT;
    type_breakdown JSONB;
    type_read_rates JSONB;
    last_notification_at TIMESTAMP;
    last_read_at TIMESTAMP;
BEGIN
    -- Get total notifications
    SELECT COUNT(*) INTO total_notifications
    FROM notifications 
    WHERE notifications.user_id = get_user_notification_stats.user_id;

    -- Get unread count
    SELECT COUNT(*) INTO unread_count
    FROM notifications 
    WHERE notifications.user_id = get_user_notification_stats.user_id 
    AND is_read = false;

    -- Calculate read count and rate
    read_count := total_notifications - unread_count;
    read_rate := CASE 
        WHEN total_notifications > 0 THEN read_count::FLOAT / total_notifications::FLOAT 
        ELSE 0 
    END;

    -- Get type breakdown
    SELECT jsonb_object_agg(type, count) INTO type_breakdown
    FROM (
        SELECT type, COUNT(*) as count
        FROM notifications 
        WHERE notifications.user_id = get_user_notification_stats.user_id
        GROUP BY type
    ) t;

    -- Get type read rates
    SELECT jsonb_object_agg(type, read_rate) INTO type_read_rates
    FROM (
        SELECT 
            type,
            CASE 
                WHEN COUNT(*) > 0 THEN COUNT(*) FILTER (WHERE is_read = true)::FLOAT / COUNT(*)::FLOAT
                ELSE 0
            END as read_rate
        FROM notifications 
        WHERE notifications.user_id = get_user_notification_stats.user_id
        GROUP BY type
    ) t;

    -- Get timestamps
    SELECT MAX(created_at) INTO last_notification_at
    FROM notifications 
    WHERE notifications.user_id = get_user_notification_stats.user_id;

    SELECT MAX(read_at) INTO last_read_at
    FROM notifications 
    WHERE notifications.user_id = get_user_notification_stats.user_id
    AND read_at IS NOT NULL;

    -- Build result
    result := jsonb_build_object(
        'total_notifications', total_notifications,
        'unread_count', unread_count,
        'read_count', read_count,
        'read_rate', read_rate,
        'type_breakdown', COALESCE(type_breakdown, '{}'::jsonb),
        'type_read_rates', COALESCE(type_read_rates, '{}'::jsonb),
        'last_notification_at', last_notification_at,
        'last_read_at', last_read_at
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get global notification analytics
CREATE OR REPLACE FUNCTION get_global_notification_analytics(
    start_date TIMESTAMP DEFAULT NULL,
    end_date TIMESTAMP DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    total_notifications INT;
    total_users INT;
    delivery_rate FLOAT;
    read_rate FLOAT;
    click_rate FLOAT;
    avg_time_to_read FLOAT;
BEGIN
    -- Set default dates if not provided
    start_date := COALESCE(start_date, NOW() - INTERVAL '30 days');
    end_date := COALESCE(end_date, NOW());

    -- Total notifications in period
    SELECT COUNT(*) INTO total_notifications
    FROM notifications 
    WHERE created_at BETWEEN start_date AND end_date;

    -- Total active users in period
    SELECT COUNT(DISTINCT user_id) INTO total_users
    FROM notifications 
    WHERE created_at BETWEEN start_date AND end_date;

    -- Calculate delivery rate (assuming all notifications in DB were delivered)
    delivery_rate := 1.0;

    -- Calculate read rate
    SELECT 
        CASE 
            WHEN COUNT(*) > 0 THEN COUNT(*) FILTER (WHERE is_read = true)::FLOAT / COUNT(*)::FLOAT
            ELSE 0
        END INTO read_rate
    FROM notifications 
    WHERE created_at BETWEEN start_date AND end_date;

    -- Calculate click rate (notifications that have analytics events)
    SELECT 
        CASE 
            WHEN total_notifications > 0 THEN 
                COUNT(DISTINCT ae.notification_id)::FLOAT / total_notifications::FLOAT
            ELSE 0
        END INTO click_rate
    FROM notification_analytics_events ae
    WHERE ae.event_name = 'notification_clicked'
    AND ae.created_at BETWEEN start_date AND end_date;

    -- Average time to read (in minutes)
    SELECT AVG(EXTRACT(EPOCH FROM (read_at - created_at))/60) INTO avg_time_to_read
    FROM notifications 
    WHERE created_at BETWEEN start_date AND end_date
    AND read_at IS NOT NULL;

    -- Build result
    result := jsonb_build_object(
        'period', jsonb_build_object(
            'start_date', start_date,
            'end_date', end_date
        ),
        'total_notifications', total_notifications,
        'total_users', total_users,
        'delivery_rate', delivery_rate,
        'read_rate', COALESCE(read_rate, 0),
        'click_rate', COALESCE(click_rate, 0),
        'avg_time_to_read_minutes', COALESCE(avg_time_to_read, 0)
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get notification type performance
CREATE OR REPLACE FUNCTION get_notification_type_performance(
    start_date TIMESTAMP DEFAULT NULL,
    end_date TIMESTAMP DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    -- Set default dates if not provided
    start_date := COALESCE(start_date, NOW() - INTERVAL '30 days');
    end_date := COALESCE(end_date, NOW());

    SELECT jsonb_object_agg(
        type,
        jsonb_build_object(
            'total_sent', total_sent,
            'read_count', read_count,
            'read_rate', read_rate,
            'click_count', click_count,
            'click_rate', click_rate,
            'avg_time_to_read_minutes', avg_time_to_read
        )
    ) INTO result
    FROM (
        SELECT 
            n.type,
            COUNT(*) as total_sent,
            COUNT(*) FILTER (WHERE n.is_read = true) as read_count,
            CASE 
                WHEN COUNT(*) > 0 THEN COUNT(*) FILTER (WHERE n.is_read = true)::FLOAT / COUNT(*)::FLOAT
                ELSE 0
            END as read_rate,
            COUNT(DISTINCT ae.notification_id) FILTER (WHERE ae.event_name = 'notification_clicked') as click_count,
            CASE 
                WHEN COUNT(*) > 0 THEN 
                    COUNT(DISTINCT ae.notification_id) FILTER (WHERE ae.event_name = 'notification_clicked')::FLOAT / COUNT(*)::FLOAT
                ELSE 0
            END as click_rate,
            AVG(EXTRACT(EPOCH FROM (n.read_at - n.created_at))/60) FILTER (WHERE n.read_at IS NOT NULL) as avg_time_to_read
        FROM notifications n
        LEFT JOIN notification_analytics_events ae ON ae.notification_id = n.id
        WHERE n.created_at BETWEEN start_date AND end_date
        GROUP BY n.type
    ) t;

    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get user engagement metrics
CREATE OR REPLACE FUNCTION get_user_engagement_metrics(user_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    days_active INT;
    notifications_per_day FLOAT;
    avg_response_time FLOAT;
    preferred_types JSONB;
BEGIN
    -- Days active (based on notifications received in last 30 days)
    SELECT COUNT(DISTINCT DATE(created_at)) INTO days_active
    FROM notifications 
    WHERE notifications.user_id = get_user_engagement_metrics.user_id
    AND created_at >= NOW() - INTERVAL '30 days';

    -- Notifications per day average
    SELECT 
        CASE 
            WHEN days_active > 0 THEN COUNT(*)::FLOAT / days_active::FLOAT
            ELSE 0
        END INTO notifications_per_day
    FROM notifications 
    WHERE notifications.user_id = get_user_engagement_metrics.user_id
    AND created_at >= NOW() - INTERVAL '30 days';

    -- Average response time (in minutes)
    SELECT AVG(EXTRACT(EPOCH FROM (read_at - created_at))/60) INTO avg_response_time
    FROM notifications 
    WHERE notifications.user_id = get_user_engagement_metrics.user_id
    AND read_at IS NOT NULL
    AND created_at >= NOW() - INTERVAL '30 days';

    -- Preferred notification types (highest read rates)
    SELECT jsonb_agg(
        jsonb_build_object(
            'type', type,
            'count', count,
            'read_rate', read_rate
        ) ORDER BY read_rate DESC
    ) INTO preferred_types
    FROM (
        SELECT 
            type,
            COUNT(*) as count,
            CASE 
                WHEN COUNT(*) > 0 THEN COUNT(*) FILTER (WHERE is_read = true)::FLOAT / COUNT(*)::FLOAT
                ELSE 0
            END as read_rate
        FROM notifications 
        WHERE notifications.user_id = get_user_engagement_metrics.user_id
        AND created_at >= NOW() - INTERVAL '30 days'
        GROUP BY type
        HAVING COUNT(*) >= 3  -- Only include types with at least 3 notifications
    ) t;

    -- Build result
    result := jsonb_build_object(
        'days_active_last_30', days_active,
        'notifications_per_day', COALESCE(notifications_per_day, 0),
        'avg_response_time_minutes', COALESCE(avg_response_time, 0),
        'preferred_types', COALESCE(preferred_types, '[]'::jsonb),
        'calculated_at', NOW()
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get delivery trends
CREATE OR REPLACE FUNCTION get_delivery_trends(
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    group_by VARCHAR DEFAULT 'day'
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    date_trunc_format VARCHAR;
BEGIN
    -- Set date truncation format based on group_by
    CASE group_by
        WHEN 'hour' THEN date_trunc_format := 'hour';
        WHEN 'week' THEN date_trunc_format := 'week';
        ELSE date_trunc_format := 'day';
    END CASE;

    -- Get trends data
    SELECT jsonb_agg(
        jsonb_build_object(
            'period', period,
            'notifications_sent', notifications_sent,
            'notifications_read', notifications_read,
            'read_rate', read_rate,
            'unique_users', unique_users
        ) ORDER BY period
    ) INTO result
    FROM (
        SELECT 
            date_trunc(date_trunc_format, created_at) as period,
            COUNT(*) as notifications_sent,
            COUNT(*) FILTER (WHERE is_read = true) as notifications_read,
            CASE 
                WHEN COUNT(*) > 0 THEN COUNT(*) FILTER (WHERE is_read = true)::FLOAT / COUNT(*)::FLOAT
                ELSE 0
            END as read_rate,
            COUNT(DISTINCT user_id) as unique_users
        FROM notifications 
        WHERE created_at BETWEEN start_date AND end_date
        GROUP BY date_trunc(date_trunc_format, created_at)
    ) t;

    RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Export analytics data
CREATE OR REPLACE FUNCTION export_notification_analytics(
    start_date TIMESTAMP DEFAULT NULL,
    end_date TIMESTAMP DEFAULT NULL,
    event_types TEXT[] DEFAULT NULL,
    user_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    where_conditions TEXT := 'WHERE 1=1';
BEGIN
    -- Set default dates if not provided
    start_date := COALESCE(start_date, NOW() - INTERVAL '7 days');
    end_date := COALESCE(end_date, NOW());

    -- Build where conditions
    where_conditions := where_conditions || ' AND created_at BETWEEN ''' || start_date || ''' AND ''' || end_date || '''';
    
    IF event_types IS NOT NULL THEN
        where_conditions := where_conditions || ' AND event_name = ANY(' || quote_literal(event_types) || ')';
    END IF;
    
    IF user_id IS NOT NULL THEN
        where_conditions := where_conditions || ' AND user_id = ''' || user_id || '''';
    END IF;

    -- Execute dynamic query
    EXECUTE format('
        SELECT jsonb_build_object(
            ''export_info'', jsonb_build_object(
                ''start_date'', %L,
                ''end_date'', %L,
                ''event_types'', %L,
                ''user_id'', %L,
                ''exported_at'', NOW()
            ),
            ''events'', jsonb_agg(
                jsonb_build_object(
                    ''event_name'', event_name,
                    ''user_id'', user_id,
                    ''notification_id'', notification_id,
                    ''event_data'', event_data,
                    ''created_at'', created_at
                ) ORDER BY created_at DESC
            )
        )
        FROM notification_analytics_events %s',
        start_date, end_date, event_types, user_id, where_conditions
    ) INTO result;

    RETURN COALESCE(result, jsonb_build_object('events', '[]'::jsonb));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_user_notification_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_global_notification_analytics(TIMESTAMP, TIMESTAMP) TO authenticated;
GRANT EXECUTE ON FUNCTION get_notification_type_performance(TIMESTAMP, TIMESTAMP) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_engagement_metrics(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_delivery_trends(TIMESTAMP, TIMESTAMP, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION export_notification_analytics(TIMESTAMP, TIMESTAMP, TEXT[], UUID) TO authenticated;