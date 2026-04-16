import { supabase } from "../../assets/js/supabase-config.js";
const uploadForm = document.getElementById("upload-form");
const display_picture = document.getElementById("profile-pic");
const logoutBtn = document.getElementById("logout-btn");
document.addEventListener('DOMContentLoaded', function() {
    const uploadPfp = async (file) => {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
            Swal.fire({
                title: "Error!",
                text: "User not authenticated",
                icon: "error",
                confirmButtonText: "Okay",
            }).then(()=> {
                window.location.href = "student-login.html";
            })
            return;
        }
    
        const userId = user.id;
        const filePath = `display_pictures/${userId}.jpg`; // Unique path per user
        const reloadWithoutCache = () => {
            const imgElement = document.getElementById("profile-picture"); // Update this to your actual img element ID
            if (imgElement) {
                imgElement.src = imgElement.src.split("?")[0] + `?t=${new Date().getTime()}`;
            }
            location.reload();
        };
        
        const { error: uploadError } = await supabase.storage
            .from("display_pictures")
            .upload(filePath, file, { upsert: true });
    
        if (uploadError) {
            Swal.fire({
                title: "Error!",
                text: "Error uploading image. Please try again.",
                icon: "error",
                confirmButtonText: "Okay",
            });
            return;
        }
    
        // Get the public URL of the uploaded image
        const { data } = supabase.storage.from("display_pictures").getPublicUrl(filePath);
        const imageUrl = data.publicUrl;
    
        // Store the image URL in the database
        const { error: updateError } = await supabase
            .from("students")
            .update({ profile_picture_url: imageUrl })
            .eq("user_id", userId);
    
        if (updateError) {
            Swal.fire({
                title: "Error!",
                text: "Error updating profile picture. Please try again.",
                icon: "error",
                confirmButtonText: "Okay",
            });
            return;
        }
    
        Swal.fire({
            title: "Success!",
            text: "Profile picture updated successfully.",
            icon: "success",
            confirmButtonText: "Okay",
        }).then(() => {
            sessionStorage.clear();
            reloadWithoutCache();
        });
    }
    uploadForm.addEventListener("submit", async (e) => {
        e.preventDefault();
        uploadPfp(display_picture.files[0])
    });

    // Function to fetch student data
    const fetchStudentData = async () => {
    const { data: { user }, error } = await supabase.auth.getUser();

    if (error || !user) {
        Swal.fire({
            title: "Error!",
            text: "User not authenticated",
            icon: "error",
            confirmButtonText: "Okay",
        }).then(()=>{
            window.location.href = "student-login.html";
        })
        return;
    }

    // Check for RSVP (using event_registrations table)
    const { data:rsvpData, error: rsvpError } = await supabase
        .from("event_registrations")
        .select("*")
        .eq("student_id", user.id);

    if (rsvpData && rsvpData.length > 0) {
        document.getElementById("rsvp-download").style.display = "flex";
        document.getElementById("rsvp-modal-open").removeAttribute('data-bs-toggle');
        document.getElementById("rsvp-modal-open").removeAttribute('data-bs-target');
        document.getElementById("rsvp-modal-open").addEventListener("click", (event)=>{
            event.preventDefault();
            Swal.fire({
                title: "RSVP Details",
                text: "You have already RSVP'd for an event. Check the events page for more details.",
                icon: "info",
                confirmButtonText: "Okay",
            })
            return;
        })
        document.getElementById("rsvp-download").addEventListener("click", (event)=>{
            event.preventDefault();
            window.location.href = "events.html";
        })
    }

    const { data, error: fetchError } = await supabase
        .from("students")
        .select("*")
        .eq("user_id", user.id)
        .single();

    if (fetchError) {
        Swal.fire({
            title: "Error!",
            text: "Error fetching student data. Please refresh.",
            icon: "error",
            confirmButtonText: "Okay",
        })
        return;
    }
    document.getElementById("student-name").textContent = `${data.first_name} ${data.last_name}` || "Unknown";
    document.getElementById("matric_no").textContent = data.matric_number || "N/A";
    document.getElementById("course").textContent = data.department || "N/A";
    if(data.profile_picture_url){
        document.getElementById("display_picture").src = data.profile_picture_url + `?t=${new Date().getTime()}`;
    }
    };

    logoutBtn.addEventListener("click", async (e) => {
        e.preventDefault();
        const { error } = await supabase.auth.signOut();
        if (error) {
            Swal.fire({
                title: "Error!",
                text: "Error signing out. Please try again.",
                icon: "error",
                confirmButtonText: "Okay",
            });
            return;
        }
        sessionStorage.clear();
        window.location.href = "index.html";
    });
    // Call the function to fetch data
    fetchStudentData();

    const eventRsvp = async () =>{
        const { data: { user }, error } = await supabase.auth.getUser();

        if(error || !user){
            Swal.fire({
                title: "Error!",
                text: "You're not authenticated. Please signin.",
                icon: "error",
                confirmButtonText: "Okay",
            })
            return;
        }
        const userId = user.id;
        
        // Find the event ID for "Unwind and Connect" (mocking it for now or getting the latest active event)
        const { data: eventData } = await supabase
            .from("events")
            .select("id")
            .eq("title", "Unwind and Connect")
            .single();

        if (!eventData) {
            Swal.fire('Error', 'Event not found. Please contact admin.', 'error');
            return;
        }

        const eventId = eventData.id;

        // Check for existing registration
        const { data: existingReg, error: checkError } = await supabase
              .from("event_registrations")
              .select("*")
              .eq("event_id", eventId)
              .eq("student_id", userId)
              .single();
  
          if (existingReg) {
            Swal.fire({
                title: "Error!",
                text: "You already have a spot for this event. Download your ticket from the events page.",
                icon: "error",
                confirmButtonText: "Okay",
            })
            return;
          }

          const { error: insertError } = await supabase
            .from("event_registrations")
            .insert([{
                event_id: eventId,
                student_id: userId,
                payment_status: 'free' // Defaulting to free for this specific event link
            }]);

            if(insertError){
                Swal.fire({
                    title: "Error!",
                    text: "An error occurred while trying to RSVP. Please try again later.",
                    icon: "error",
                    confirmButtonText: "Okay",
                });
                return;
            }
            Swal.fire({
                title: "Success!",
                text: "You have successfully RSVP'd for the event.",
                icon: "success",
                confirmButtonText: "View Event",
            }).then(()=>{
                window.location.href = "events.html";
            })
    }
    document.getElementById("rsvp-btn").addEventListener("click", (e)=>{
        e.preventDefault();
        eventRsvp();
    })

    loadQuickResources();
});

async function loadQuickResources() {
    const container = document.getElementById('quickResourcesContainer');
    if (!container) return;

    const { data, error } = await supabase
        .from('academic_resources')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(4);

    if (error || !data || data.length === 0) {
        container.innerHTML = `
            <div class="col-12 text-center">
                <p class="text-muted">No resources available yet</p>
            </div>
        `;
        return;
    }

    const typeColors = {
        'Tutorial': { bg: '#e3f2fd', color: '#1976d2' },
        'Documentation': { bg: '#f3e5f5', color: '#7b1fa2' },
        'Course': { bg: '#e8f5e9', color: '#388e3c' },
        'Book': { bg: '#fff3e0', color: '#f57c00' },
        'Tool': { bg: '#fce4ec', color: '#c2185b' },
        'Other': { bg: '#eceff1', color: '#546e7a' }
    };

    container.innerHTML = data.map(r => {
        const colors = typeColors[r.resource_type] || { bg: '#eceff1', color: '#546e7a' };
        return `
            <div class="col-lg-3 col-md-6">
                <a href="${escapeHtml(r.url)}" target="_blank" class="text-decoration-none">
                    <div class="service-item position-relative h-100" style="background: ${colors.bg}; border-left: 4px solid ${colors.color};">
                        <i class="bi bi-link-45deg icon" style="color: ${colors.color};"></i>
                        <div>
                            <h3 style="color: ${colors.color};">${escapeHtml(r.title)}</h3>
                            <p class="text-muted small">${escapeHtml(r.resource_type)} ${r.category ? '• ' + escapeHtml(r.category) : ''}</p>
                        </div>
                    </div>
                </a>
            </div>
        `;
    }).join('');
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}